{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  user = config.${namespace}.user.name;

  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop = {
    enable = mkEnableOption "Whether to enable desktop theming";
  };

  config = mkIf cfg.enable {
    ${namespace}.home.extraOptions = {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
      };

      systemd.user.sessionVariables = config.home-manager.users.${user}.home.sessionVariables;
    };

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

  };
}
