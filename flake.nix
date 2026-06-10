{
  description = "kitty fork (OSC 9;4 graphical progress bar): overlay + package, src = self";
  # pinned to nixos-config's nixpkgs lock rev so `nix build .#` reproduces the exact derivation the system overlay builds; newer nixpkgs kitty derivations expect newer upstream sources (their preCheck rms a test file this fork's rev predates)
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/e4bae1bd10c9c57b2cf517953ab70060a828ee6f";
  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      overlay = final: prev: {
        kitty = prev.kitty.overrideAttrs (old: {
          version = "0.46.0-dev";
          src = self;
          patches = [ ];
          # newer nixpkgs (kitty >= 0.47) hard-rms a sandbox-incompatible test file that this 0.46-dev tree doesn't have yet; tolerate its absence so the override works across nixpkgs revs
          preCheck = builtins.replaceStrings
            [ "rm tools/utils/machine_id/api_test.go" ]
            [ "rm -f tools/utils/machine_id/api_test.go" ]
            (old.preCheck or "");
          env = (old.env or { }) // { GOTOOLCHAIN = "local"; };
          inherit ((prev.buildGo125Module {
            pname = "kitty-go-modules";
            version = "0.46.0-dev";
            src = self;
            vendorHash = "sha256-abvQN11gsanL7vV8dhEJFTMOdBJFtZAxMo+FWbF+s+c=";
            env.GOTOOLCHAIN = "local";
          })) goModules;
        });
      };
    in {
      overlays.default = overlay;
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
        in { default = pkgs.kitty; });
    };
}
