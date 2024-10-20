{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  # hyprpaper-package = inputs.hyprpaper.packages.${system}.hyprpaper;

  cfg = config.${namespace}.desktop.addons.hyprpaper;

  username = config.${namespace}.user.name;
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

      services.hyprpaper = {
        enable = true;
        settings = {
          preload = [
            "/home/${username}/Pictures/firewatch.jpg"
          ];
          wallpaper = "monitor DP-2, /home/${username}/Pictures/firewatch.jpg";
        };
      };
    };
  };
}
