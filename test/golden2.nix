with import <nixpkgs> {}; let
  build5 = pkgs.runCommand "build5" {} ''
    sleep 3s
    echo "output of build1" > $out
  '';
  build6 = pkgs.runCommand "build6" {} ''
    sleep 3s
    cat ${build5}
    echo "test" > $out
  '';
  build7 = pkgs.runCommand "build7" {} ''
    sleep 3s
    echo "output of build1" > $out
  '';
  build8 = pkgs.runCommand "build8" {} ''
    sleep 3s
    cat ${build7}
    cat ${build4}
    echo "test" > $out
  '';
  build1 = pkgs.runCommand "build1" {} ''
    sleep 3s
    cat ${build11}
    echo "output of build1" > $out
  '';
  build2 = pkgs.runCommand "build2" {} ''
    sleep 3s
    cat ${build5}
    cat ${build6}
    cat ${build1}
    echo "test" > $out
  '';
  build9 = pkgs.runCommand "build9" {} ''
    sleep 3s
    cat ${build2}
    echo "test" > $out
  '';
  build3 = pkgs.runCommand "build3" {} ''
    cat ${build1}
    cat ${build9}
    sleep 3s
    cat ${build4}
    cat ${build8}
    echo "test" > $out
  '';
  build4 = pkgs.runCommand "build4" {} ''
    cat ${build10}
    echo "test" > $out
  '';
  build10 = pkgs.runCommand "build10" {} ''
    sleep 3s
    echo "test" > $out
  '';
  build11 = pkgs.runCommand "build11" {} ''
    sleep 3s
    echo "test" > $out
  '';
in
  build3
