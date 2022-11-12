{ pkgs }:
with pkgs;
    runCommand "data-tst-flake" {
        # Here you can use any variables line consts or fetch-urls
        cmd = "ls -al";
        data = fetchurl {
            url = "https://raw.githubusercontent.com/cattingcat/language-befunge/master/.ghci";
            sha256 = "sha256-gV+R5iyH09uHCx0hk417LG9yBW8v6JrUfKMCGLEInFk=";
        };
        customMessage = "raw";
        } ''
            mkdir $out
            touch          $out/file
            $cmd        >> $out/file
            echo "----" >> $out/file
            pwd         >> $out/file
            echo "----" >> $out/file
            echo $customMessage >> $out/file 
            echo "----" >> $out/file
            cat $data   >> $out/file
        ''

# you don't neew makeOverridable for derivations, it supports it natively via overrideAttrs