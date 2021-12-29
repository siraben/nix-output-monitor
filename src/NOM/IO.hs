module NOM.IO where

import Relude
import Prelude ()

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (concurrently_, race_)
import Control.Concurrent.STM (check, swapTVar)
import Control.Exception (IOException, try)
import qualified Data.Text as Text
import qualified Data.Text.IO as TextIO
import Data.Time (UTCTime, getCurrentTime)
import System.IO (hFlush)

import qualified Streamly as S
import qualified Streamly.Data.Fold as FL
import qualified Streamly.Data.Unfold as UF
import qualified Streamly.Internal.Data.Unfold as UF
import Streamly.Prelude ((.:))
import qualified Streamly.Prelude as S

import Data.Attoparsec.Text (IResult (..), Parser, Result, feed, parse)

import System.Console.ANSI (SGR (Reset), clearLine, cursorUpLine, setSGRCode)
import System.Console.Terminal.Size (Window (Window), size)

import NOM.Print.Table as Table (displayWidth, truncate)
import NOM.Update.Monad (UpdateMonad)

type Stream = S.SerialT IO
type Output = Text
type UpdateFunc update state output = forall (m :: Type -> Type). UpdateMonad m => (update -> state -> m (state, output))
type OutputFunc state = UTCTime -> state -> Output

parseStream :: forall update. Parser update -> Stream Text -> Stream update
parseStream (parse -> parseFresh) = S.concatMap snd . S.scanl' step (Nothing, mempty)
 where
  step :: (Maybe (Text -> Result update), Stream update) -> Text -> (Maybe (Text -> Result update), Stream update)
  step (maybe parseFresh feed . fmap Partial . fst -> parse') = fix process mempty . parse'
  process = \parseRest acc -> \case
    Done "" result -> (Nothing, acc <> pure result)
    Done rest result -> parseRest (acc <> pure result) (parseFresh rest)
    Fail{} -> (Nothing, acc)
    Partial cont -> (Just cont, acc)

readTextChunks :: UF.Unfold IO Handle Text
readTextChunks = UF.fromStream1 \handle -> fix \(streamTail :: Stream Text) ->
  liftIO (try (TextIO.hGetChunk handle)) >>= \case
    Left (_ :: IOException) -> streamTail
    Right "" -> mempty
    Right input -> input .: streamTail

runUpdates ::
  forall update state output.
  Semigroup output =>
  TVar state ->
  TVar output ->
  UpdateFunc update state output ->
  FL.Fold IO update ()
runUpdates stateVar bufferVar updater = FL.drainBy \input -> do
  oldState <- readTVarIO stateVar
  (newState, output') <- updater input oldState
  atomically do
    writeTVar stateVar newState
    modifyTVar' bufferVar (<> output')

writeStateToScreen :: forall state. TVar Int -> TVar state -> TVar Output -> OutputFunc state -> IO ()
writeStateToScreen linesVar stateVar bufferVar printer = do
  now <- getCurrentTime
  terminalSize <- size
  (writtenLines, buffer, linesToWrite, output) <- atomically $ do
    buildState <- readTVar stateVar
    let output = truncateOutput terminalSize (printer now buildState)
        linesToWrite = length (Text.lines output)
    writtenLines <- swapTVar linesVar linesToWrite
    buffer <- swapTVar bufferVar mempty
    pure (writtenLines, buffer, linesToWrite, output)
  liftIO $ do
    replicateM_ writtenLines $ do
      cursorUpLine 1
      clearLine
    putText buffer
    when (linesToWrite > 0) $ putTextLn output
    hFlush stdout

interact ::
  forall update state.
  Parser update ->
  UpdateFunc update state Output ->
  OutputFunc state ->
  state ->
  IO state
interact parser updater printer initialState =
  S.unfold readTextChunks stdin
    & processTextStream parser updater (Just printer) initialState

processTextStream ::
  forall update state.
  Parser update ->
  UpdateFunc update state Output ->
  Maybe (OutputFunc state) ->
  state ->
  Stream Text ->
  IO state
processTextStream parser updater printerMay initialState inputStream = do
  stateVar <- newTVarIO initialState
  bufferVar <- newTVarIO mempty
  let keepProcessing :: IO ()
      keepProcessing =
        inputStream
          & parseStream parser
          & S.fold (runUpdates stateVar bufferVar updater)
      waitForInput :: IO ()
      waitForInput = atomically $ check . not . Text.null =<< readTVar bufferVar
  case printerMay of
    Just printer -> do
      linesVar <- newTVarIO 0
      let writeToScreen :: IO ()
          writeToScreen = writeStateToScreen linesVar stateVar bufferVar printer
          keepPrinting :: IO ()
          keepPrinting = forever do
            race_ (concurrently_ (threadDelay 20000) waitForInput) (threadDelay 1000000)
            writeToScreen
      race_ keepProcessing keepPrinting
      writeToScreen
    Nothing -> keepProcessing
  readTVarIO stateVar

truncateOutput :: Maybe (Window Int) -> Text -> Text
truncateOutput win output = maybe output go win
 where
  go (Window rows columns) = Text.intercalate "\n" $ truncateColumns columns <$> truncatedRows rows
  truncateColumns columns line = if displayWidth line > columns then Table.truncate (columns - 1) line <> "…" <> toText (setSGRCode [Reset]) else line
  truncatedRows rows =
    if length outputLines >= rows
      then take 1 outputLines <> [" ⋮ "] <> drop (length outputLines + 4 - rows) outputLines
      else outputLines
  outputLines = Text.lines output