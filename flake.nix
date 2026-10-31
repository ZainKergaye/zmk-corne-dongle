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
      in
      rec {
        default = firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "firmware";
          src = sourceFiles;
          board = "nice_nano_v2";
          shield = "eyelash_corne_%PART%";
          zephyrDepsHash = "sha256-pGA26rJBYqZFChg72h/CVbm4hrnpzoqXPxK7Bk0uOhQ=";
          enableZmkStudio = false;
        };
      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
