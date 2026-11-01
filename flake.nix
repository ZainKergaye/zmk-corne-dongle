{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in
    {
      packages = forAllSystems (system:
      let
        sourceFiles = lib.sourceFilesBySuffices self [
          ".c"
          ".h"
          ".board"
          ".cmake"
          ".conf"
          ".defconfig"
          ".dts"
          ".dtsi"
          ".json"
          ".keymap"
          ".overlay"
          ".shield"
          ".yml"
          "_defconfig"
          "CMakeLists.txt"
        ];
        zmk = zmk-nix.legacyPackages.${system};
        westDeps = (zmk.buildKeyboard {
          name = "firmware-deps";
          src = sourceFiles;
          board = "nice_nano_v2";
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
        }).westDeps;
      in
      rec {
        default = firmware;

        # Release build: both split halves. Use one of the targets below while
        # iterating so Nix only rebuilds the controller being flashed.
        firmware = zmk.buildSplitKeyboard {
          name = "firmware";
          src = sourceFiles;
          board = "nice_nano_v2";
          shield = "eyeslash_corne_peripheral_%PART%";
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
          inherit westDeps;
          enableZmkStudio = false;
        };

        dongle = zmk.buildKeyboard {
          name = "firmware-dongle";
          src = sourceFiles;
          board = "nice_nano_v2";
          shield = "eyeslash_corne_central_dongle dongle_display";
          snippets = [ "studio-rpc-usb-uart" ];
          extraCmakeFlags = [ "-DCONFIG_ZMK_STUDIO=y" "-DCONFIG_ZMK_STUDIO_LOCKING=n" ];
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
          inherit westDeps;
        };

        left = zmk.buildKeyboard {
          name = "firmware-left";
          src = sourceFiles;
          board = "nice_nano_v2";
          shield = "eyeslash_corne_peripheral_left nice_view_custom";
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
          inherit westDeps;
        };

        right = zmk.buildKeyboard {
          name = "firmware-right";
          src = sourceFiles;
          board = "nice_nano_v2";
          shield = "eyeslash_corne_peripheral_right nice_view_custom";
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
          inherit westDeps;
        };
      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
