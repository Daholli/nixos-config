{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.graphviz;
in
{
  options.${namespace}.apps.graphviz = {
    enable = mkBoolOpt true "Whether or not you want to install graphviz";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ graphviz ];

    home.shellAliases = {
      nixsize = "nix-du -n=50 | dot -Tsvg > ~/Pictures/store.svg";
    };
  };
}
