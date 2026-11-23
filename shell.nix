# Used by .envrc: `use flake` would `nix flake archive` every input on each lock bump.
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  input = name: builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.${name}}.locked;
  pkgs = import (input "nixpkgs") { };
  treefmt =
    ((import (input "treefmt-nix")).evalModule pkgs ./modules/flake-parts/_treefmt.nix)
    .config.build.wrapper;
  git-hooks = input "git-hooks";
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
  packages = pre-commit.enabledPackages ++ [ pkgs.pre-commit ];
  inherit (pre-commit) shellHook;
}
