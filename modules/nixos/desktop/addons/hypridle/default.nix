{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.desktop.addons.hypridle;

  username = config.${namespace}.user.name;
in
{
  options.${namespace}.desktop.addons.hypridle = {
    enable = mkEnableOption "Enable HyprIdle";
  };

  config = mkIf cfg.enable {
    snowfallorg.users.${username}.home.config = {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "hyprlock";
          };

          listener = [
            {
              timeout = 900;
              on-timeout = "hyprlock";
            }
            {
              timeout = 1200;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
  };
}
