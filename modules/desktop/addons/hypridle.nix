{
  flake.modules.homeManager.cholli =
    { lib, osConfig, ... }:
    {
      config = lib.mkIf osConfig.programs.hyprland.enable {
        services.hypridle = {
          enable = true;
          settings = {
            general = {
              after_sleep_cmd = "hyprctl dispatch dpms on";
              ignore_dbus_inhibit = false;
              lock_cmd = "hyprlock-blur";
            };

            listener = [
              {
                timeout = 600;
                on-timeout = "loginctl lock-session";
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
