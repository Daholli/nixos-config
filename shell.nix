# Used by .envrc: `use flake` would `nix flake archive` every input on each lock bump.
let
  inputs = (import ./.tack) { };
  pkgs = import inputs.nixpkgs { };
  treefmt =
    ((import inputs.treefmt-nix).evalModule pkgs ./modules/flake-parts/_treefmt.nix)
    .config.build.wrapper;
  inherit (inputs) git-hooks;
  pre-commit =
    pkgs.callPackage "${git-hooks}/nix/run.nix"
      {
        tools = import "${git-hooks}/nix/call-tools.nix" pkgs;
        isFlakes = false;
      }
      {
        src = ./.;
        hooks.treefmt = {
          enable = true;
          package = treefmt;
        };
      };
in
pkgs.mkShell {
  packages = pre-commit.enabledPackages ++ [ pkgs.tack ];
  inherit (pre-commit) shellHook;
}
