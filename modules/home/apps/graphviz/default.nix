{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.graphviz;
in
{
  options.wyrdgard.apps.graphviz = {
    enable = mkBoolOpt true "Whether or not you want to install graphviz";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ graphviz ];

    home.shellAliases = {
      nixsize = "nix-du -n=50 | dot -Tsvg > ~/Pictures/store.svg";
    };
  };
}
