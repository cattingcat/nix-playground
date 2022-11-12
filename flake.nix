# nix docs: https://devdocs.io/nix/nixpkgs/stable/index#trivial-builder-writeText
# flake guide: https://www.tweag.io/blog/2020-05-25-flakes/
# flake utils: https://github.com/numtide/flake-utils


{
  description = "A very basic flake";

  inputs = {
    # see https://github.com/NixOS/nixpkgs/blob/master/flake.nix legacyPackages
    unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, unstable }: {
    packages.aarch64-darwin.say-qwe = 
      # importing via nixpkgs/default.nix (:l <nixpkgs>   in nix repl)
      with import unstable {system = "aarch64-darwin";};
      let 
        # Using as flake (flake.nix) (:lf nixpkgs   in nix repl)
        pkgs = unstable.legacyPackages.aarch64-darwin;

        # using packages from <nixpkgs>
        h = pkgs.hello;
        hs = pkgs.haskell.compiler.ghc942;
        mc = pkgs.coqPackages.mathcomp;

        # callPackage implicitly place arguments instead of `import ./data-flake.nix { pkgs }`
        dataPackage = callPackage ./data-flake.nix { };

        # overrideAttrs pattern for overriding some properties of derivation
        #  use just override for other object
        #  Don't use overrideDerivation
        data = dataPackage.overrideAttrs (a: { 
         customMessage = "Hello from attrs override derivation"; 
        });

        # Writing script during build time, you can wrap other packages like ${data}
        sayer = writeTextFile {
          name = "qwe-sayer";
          destination = "/bin/say-qwe";
          executable = true;
          text = ''
            #!${pkgs.stdenv.shell}
            echo "Qwe!"
            cat ${data}/file
          '';
        };
        haskSay = writeTextFile {
          name = "haskell-script";
          destination = "/bin/foo.hs";
          executable = true;
          text = ''
            #!${hs}/bin/runghc
            ${builtins.readFile ./foo.hs}
          '';
        };
      in 
        runCommand "say-qwe" {} ''
          mkdir $out
          mkdir $out/bin
          mkdir $out/data

          ${h}/bin/hello > $out/data/native-hello
          ls -al         > $out/data/file-ls
          cp ${data}/file  $out/data/file-data
          cp -r ${mc}      $out/data/mathcomp
          cp ${sayer}/bin/say-qwe  $out/bin/say-qwe
          cp ${haskSay}/bin/foo.hs $out/bin/foo.hs
        '';

    packages.x86_64-linux.hello = unstable.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    devShells.aarch64-darwin.default = 
      with import unstable {system = "aarch64-darwin";};
      let
        pkgs = unstable.legacyPackages.aarch64-darwin;
        wrap = pkgs.makeWrapper;
        h = pkgs.hello;
        hs = pkgs.haskell.compiler.ghc942;

        # making wrapper of hello with specific flags
        wrapped-hello = runCommand "wrapped-hello" {
          buildInputs = [ wrap ];
        } ''
          mkdir $out
          mkdir $out/bin
          makeWrapper ${h}/bin/hello $out/bin/hello --add-flags "-t"
        '';

        # makeWrapper copies program to output (see also pkgs.symlinkJoin)

        # Wraps programm from path amd makes symlink
        #  wrapProgram $out/bin/hello --add-flags "-t"

        b = writeTextFile {
          name = "shell-helper";
          destination = "/bin/say-qwe";
          executable = true;
          text = ''
            #!${pkgs.stdenv.shell}
            echo "Qwe!"
            
          '';
        };
      in
        mkShell {
          buildInputs = [
            hs
            b
            wrapped-hello
          ];  
          shellHook = ''
            export PS1='\e[1;34mdev > \e[0m'
          '';
        };
  };
}
