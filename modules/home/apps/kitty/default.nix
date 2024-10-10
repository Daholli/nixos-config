{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.apps.kitty;
in
{
  options.${namespace}.apps.kitty = {
    enable = mkEnableOption "Kitty";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kitty ];

    programs.kitty = {
      enable = true;
      themeFile = "tokyo_night_night";
      font = {
        name = "Code New Roman";
        size = 15;
      };
      shellIntegration.enableFishIntegration = true;
      settings = {
        "background_opacity" = "0.90";
        "shell" = "fish";
        "confirm_os_window_close" = "0";
      };
    };
  };
}
