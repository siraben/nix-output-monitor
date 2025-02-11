# Revision history for nix-output-monitor

## 1.1.3.0 -- 2022-03-21
* Update parser to correctly detect failed builds on nix 2.7

## 1.1.2.1 -- 2022-03-16
* Move nom-build and zsh completion files from nixpkgs into this repo
* Internal refactoring for streamly >= 0.8 and ghc 9.0 compat

## 1.1.2.0 -- 2022-03-12
* Fix the bug that the colored errors of newer nix version didn‘t get parsed as errors.

## 1.1.1.0 -- 2022-03-08
* Only show dependency graph when necessary
* Only show build counts for host, when not zero

## 1.1.0.0 -- 2022-03-07
* Replace list of running and failed builds with a continually updated dependency graph
* A lot of small convenience improvements e.g. nicer timestamps
* Make input parsing more robust via using streamly. This hopefully fixes #23.
* Symbols: Change a few used symbols and force text representation

## 1.0.5.0 -- 2022-03-05
* Make the parser for storepath accept more storepaths which actually occur in the wild.

## 1.0.4.2 -- 2022-02-25
* Other fixes for relude 1.0 compat

## 1.0.4.1 -- 2022-02-25
* Rename an internal variable for relude 1.0 compat

## 1.0.4.0 -- 2021-12-03
* Make parsing a bit more flexible for better nix 2.4 compatibility.

## 1.0.3.3 -- 2021-09-24
* Reduce flickering for some terminal emulators. Thanks @pennae

## 1.0.3.2 -- 2021-09-17
* Improve warning when nom received no input, again.

## 1.0.3.1 -- 2021-04-30
* Improve warning when nom received no input

## 1.0.3.0 -- 2021-03-04

* Internal refactoring
* State of last planned build is now displayed in bottom bar

## 1.0.2.0 -- 2021-03-04

### Bug fixes

* Introduce proper file locking for build times DB. Multiple running nom instances should work now with every single build time being recorded.
* Improved the parser for failed build messages. Should now correctly work with `nix-build -k`.

## 1.0.1.1 -- 2021-02-21

* Use a different symbol for the total

## 1.0.1.0 -- 2021-02-21

* Catch IO errors and try to restart

## 1.0.0.0 -- 2021-02-21

* Added recognition of `--check` builds
* Added recognition of failed builds
* Display final derivation in status line
* Exit with failure code when a failed build was recognized
* Truncate output so that it works in too small terminal windows
* Save past build times in cache and display the moving average to the user

## 0.1.0.3 -- 2021-02-20

* Reworked the printing code to make it more robust

## 0.1.0.2 -- 2020-10-18

* Fixed a layout bug when no builds are going on.

## 0.1.0.1 -- 2020-10-16

* Changed emojis for completed to checkmark and waiting to hourglass.

## 0.1.0.0 -- 2020-10-03

* First version. Released on an unsuspecting world.
