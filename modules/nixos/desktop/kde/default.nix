{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.${namespace}.desktop.kde;
in
{
  options.${namespace}.desktop.kde = with types; {
    enable = mkEnableOption "Whether to enable a kde plasma6";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xdg-utils
      kdePackages.qtbase
    ];

    services = {
      xserver = enabled;
      desktopManager.plasma6 = enabled;
    };
  };
}
