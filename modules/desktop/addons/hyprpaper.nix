{
  flake.modules.homeManager.cholli =
    { lib, osConfig, ... }:
    let
      picture-path = "/home/cholli/Pictures/firewatch.jpg";
    in
    {
      config = lib.mkIf (osConfig.networking.hostName == "yggdrasil") {

        home.file = {
          # https://www.reddit.com/r/WidescreenWallpaper/comments/13hib3t/purple_firewatch_3840x1620/
          "Pictures/firewatch.jpg".source = ./firewatch.jpg;
        };

        wayland.windowManager.hyprland.settings.exec-once = [
          ''hyprctl hyprpaper wallpaper "DP-1,${picture-path}"''
        ];

        services.hyprpaper = {
          enable = true;
          settings = {
            preload = [ picture-path ];
            wallpaper = "DP-1,${picture-path}";
          };
        };

      };
    };
}
