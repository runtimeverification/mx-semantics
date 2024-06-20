{
  description = "K Semantics of MultiversX";

  inputs = {
    wasm-semantics.url = "github:runtimeverification/wasm-semantics/v0.1.65";
    k-framework.url = "github:runtimeverification/k/v7.1.8";
    pyk.url = "github:runtimeverification/k/v7.1.8?dir=pyk";
    nixpkgs.follows = "k-framework/nixpkgs";
    flake-utils.follows = "k-framework/flake-utils";
    rv-utils.url = "github:runtimeverification/rv-nix-tools";
    nixpkgs-pyk.follows = "pyk/nixpkgs";
    poetry2nix.follows = "pyk/poetry2nix";
    blockchain-k-plugin = {
      url =
        "github:runtimeverification/blockchain-k-plugin/3054e0fca2b5b621945e643c361a4777db4b3f52";
      inputs.flake-utils.follows = "k-framework/flake-utils";
      inputs.nixpkgs.follows = "k-framework/nixpkgs";
    };
  };

  outputs =
    { self, k-framework, nixpkgs, flake-utils, rv-utils, pyk, nixpkgs-pyk, poetry2nix, wasm-semantics, blockchain-k-plugin }@inputs:
    let
      overlay = (final: prev:
        let
          src = prev.lib.cleanSource (prev.nix-gitignore.gitignoreSourcePure [
            "/.github"
            "flake.lock"
            ./.gitignore
          ] ./.);

          version = self.rev or "dirty";

          nixpkgs-pyk = import inputs.nixpkgs-pyk {
            system = prev.system;
            overlays = [ pyk.overlay ];
          };

          python310-pyk = nixpkgs-pyk.python310;

          poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { pkgs = nixpkgs-pyk; };
        in {
          kmultiversx-src = prev.stdenv.mkDerivation {
            name = "kmultiversx-${self.rev or "dirty"}-src";
            src = prev.lib.cleanSource
              (prev.nix-gitignore.gitignoreSourcePure [
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
              nixpkgs-pyk.pyk-python310
              k-framework.packages.${system}.k
              kmultiversx-pyk 
              cmake
              openssl.dev
              clang
              mpfr
              pkg-config
              procps
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
            python = nixpkgs-pyk.python310;
            projectDir = ./kmultiversx;
            src = rv-utils.lib.mkSubdirectoryAppSrc {
              pkgs = import nixpkgs { system = prev.system; };
              src = ./kmultiversx;
              subdirectories = [ "pykwasm" ];
              cleaner = poetry2nix.cleanPythonSources;
            };
            overrides = poetry2nix.overrides.withDefaults
            (finalPython: prevPython: {
              pyk = nixpkgs-pyk.pyk-python310;
              pykwasm = wasm-semantics.packages.${prev.system}.kwasm-pyk;
              hypothesis = prevPython.hypothesis.overridePythonAttrs (old: {
                  propagatedBuildInputs = prev.lib.filter
                    (x: !(prev.lib.strings.hasInfix "attrs" x.name || prev.lib.strings.hasInfix "exceptiongroup" x.name))
                    old.propagatedBuildInputs;
                  buildInputs = (old.buildInputs or []) ++ [ finalPython.attrs finalPython.exceptiongroup ];
              });
            });
            groups = [ ];
            checkGroups = [ ];
            postInstall = ''
              mkdir -p $out/${nixpkgs-pyk.python310.sitePackages}/kmultiversx/kdist/plugin
              cp -r ${prev.blockchain-k-plugin-src}/* $out/${nixpkgs-pyk.python310.sitePackages}/kmultiversx/kdist/plugin/
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
          overlays = [
            blockchain-k-plugin.overlay
            overlay
          ];
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
