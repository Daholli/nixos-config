{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.graphical-interface.display-manager.greetd;

  hyperland = config.wyrdgard.graphical-interface.desktop-manager.hyperland;
  hyprland-session = "${inputs.hyprland.packages.${pkgs.system}.hyperland}/share/wayland-sessions";
  kde-session = "${inputs.plasma6.packages.${pkgs.system}.plasma6}/share/wayland-sessions";

  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session";

  command =
    if hyperland.enable then
      "${tuigreet} --sessions ${hyprland-session}"
    else
      "${tuigreet} --sessions ${kde-session}";
in
{
  options.wyrdgard.graphical-interface.display-manager.greetd = with types; {
    enable = mkEnableOption "Whether to enable a sddm";
  };

  config = mkIf cfg.enable {
    services = {
      xserver = enabled;
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = command;
            user = config.wyrdgard.user.name;
          };
        };
      };
    };
  };
}
