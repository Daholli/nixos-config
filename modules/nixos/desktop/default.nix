{
  lib,
  config,
  pkgs,
  ...
}:
let
  user = config.wyrdgard.user.name;
in
{
  config = {
    wyrdgard.home.extraOptions = {
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
