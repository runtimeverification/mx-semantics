{
  description = "K Semantics of MultiversX";

  inputs = {
    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.111";
    k-framework.follows = "wasm-semantics/k-framework";
    nixpkgs.follows = "k-framework/nixpkgs";
    flake-utils.follows = "k-framework/flake-utils";
    rv-utils.follows = "k-framework/rv-utils";
    poetry2nix.follows = "k-framework/poetry2nix";
    blockchain-k-plugin = {
      url =
        "github:runtimeverification/blockchain-k-plugin/e6994c21c59dd2d15ddb97d5169d78aa6645a8fb";
      inputs.flake-utils.follows = "k-framework/flake-utils";
      inputs.nixpkgs.follows = "k-framework/nixpkgs";
    };
  };

  outputs = { self, k-framework, nixpkgs, flake-utils, rv-utils
    , poetry2nix, wasm-semantics, blockchain-k-plugin }@inputs:
    let
      overlay = (final: prev:
        let
          src = prev.lib.cleanSource (prev.nix-gitignore.gitignoreSourcePure [
            "/.github"
            "flake.lock"
            ./.gitignore
          ] ./.);

          version = self.rev or "dirty";
          poetry2nix =
            inputs.poetry2nix.lib.mkPoetry2Nix { pkgs = prev; };
        in {
          kmultiversx-src = prev.stdenv.mkDerivation {
            name = "kmultiversx-${self.rev or "dirty"}-src";
            src = prev.lib.cleanSource (prev.nix-gitignore.gitignoreSourcePure [
              ./.gitignore
              ".github/"
              "result*"
              "*.nix"
              "deps/"
            ] ./.);
            dontBuild = true;

            installPhase = ''
              mkdir $out
              cp -r $src/* $out
              chmod -R u+w $out
              mkdir -p $out/kmultiversx/src/kmultiversx/kdist/plugin/
              cp -r ${prev.blockchain-k-plugin-src}/* $out/kmultiversx/src/kmultiversx/kdist/plugin/
            '';
          };

          kmultiversx = prev.stdenv.mkDerivation {
            pname = "kmultiversx";
            src = final.kmultiversx-src;
            inherit version;

            buildInputs = with final; [
              secp256k1
              prev.python310
              k-framework.packages.${system}.k
              kmultiversx-pyk
              boost
              cmake
              openssl.dev
              clang
              mpfr
              pkg-config
              llvmPackages.llvm
            ];

            dontUseCmakeConfigure = true;

            nativeBuildInputs = [ prev.makeWrapper ];

            enableParallelBuilding = true;

            buildPhase = ''
              export XDG_CACHE_HOME=$(pwd)
              ${
                prev.lib.optionalString
                (prev.stdenv.isAarch64 && prev.stdenv.isDarwin)
                "APPLE_SILICON=true"
              } K_OPTS="-Xmx8G -Xss512m" kdist -v build mx-semantics.* -j$NIX_BUILD_CORES
            '';

            installPhase = ''
              mkdir -p $out
              cp -r ./kdist-*/* $out/
            '';
          };

          kmultiversx-pyk = poetry2nix.mkPoetryApplication {
            python = prev.python310;
            projectDir = ./kmultiversx;
            src = rv-utils.lib.mkSubdirectoryAppSrc {
              pkgs = import nixpkgs { system = prev.system; };
              src = ./kmultiversx;
              subdirectories = [ "pykwasm" ];
              cleaner = poetry2nix.cleanPythonSources;
            };
            overrides = poetry2nix.overrides.withDefaults
              (finalPython: prevPython: {
                kframework = prev.pyk-python310.overridePythonAttrs
                  (old: {
                    propagatedBuildInputs = prev.lib.filter (x:
                      !(prev.lib.strings.hasInfix "hypothesis" x.name)
                      && !(prev.lib.strings.hasInfix "cmd2" x.name))
                      old.propagatedBuildInputs
                      ++ [ finalPython.hypothesis finalPython.cmd2 ];
                  });
                pykwasm = wasm-semantics.packages.${prev.system}.kwasm-pyk.overridePythonAttrs
                  (old: {
                    propagatedBuildInputs = prev.lib.filter
                      (x: !(prev.lib.strings.hasInfix "kframework" x.name))
                      old.propagatedBuildInputs ++ [ finalPython.kframework ];
                  });
                py-wasm = prevPython.py-wasm.overridePythonAttrs
                  (old: {
                    buildInputs = (old.buildInputs or [ ])
                      ++ [ prevPython.setuptools ];
                  });
              });
            groups = [ ];
            checkGroups = [ ];
            postInstall = ''
              mkdir -p $out/${prev.python310.sitePackages}/kmultiversx/kdist/plugin
              cp -r ${prev.blockchain-k-plugin-src}/* $out/${prev.python310.sitePackages}/kmultiversx/kdist/plugin/
            '';
          };
        });
    in flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ k-framework.overlays.pyk blockchain-k-plugin.overlay overlay ];
        };
      in {
        packages = rec {
          inherit (pkgs) kmultiversx kmultiversx-pyk;
          default = pkgs.kmultiversx;
        };
      }) // {
        overlays.default = overlay;
      };
}
