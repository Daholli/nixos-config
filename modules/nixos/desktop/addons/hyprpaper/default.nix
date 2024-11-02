{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.desktop.addons.hyprpaper;

  username = config.${namespace}.user.name;
  picture-path = "/home/${username}/Pictures/firewatch.jpg";
in
{
  options.${namespace}.desktop.addons.hyprpaper = {
    enable = mkEnableOption "Enable Hyprpaper";
  };

  config = mkIf cfg.enable {
    snowfallorg.users.${username}.home.config = {
      home.file = {
        # https://www.reddit.com/r/WidescreenWallpaper/comments/13hib3t/purple_firewatch_3840x1620/
        "Pictures/firewatch.jpg".source = ./firewatch.jpg;
      };

      wayland.windowManager.hyprland.settings.exec-once = [
        ''hyprctl hyprpaper wallpaper "DP-2,${picture-path}"''
      ];

      services.hyprpaper = {
        enable = true;
        settings = {
          preload = [ picture-path ];
          wallpaper = "DP-2,${picture-path}";
        };
      };
    };

  };
}
