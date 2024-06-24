{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.graphical-interface.desktop-manager.hyprland;
in
{
  options.wyrdgard.graphical-interface.desktop-manager.hyprland = with types; {
    enable = mkEnableOption "Whether to enable hyprland";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      polkit
      xdg-desktop-portal-hyprland
      dconf
    ];

    services.xserver = enabled;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
}
