{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.kitty;
in {
  options.wyrdgard.cli-apps.kitty = {
    enable = mkEnableOption "Kity";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
    ];
  };
}
