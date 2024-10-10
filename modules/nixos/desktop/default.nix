{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  user = config.${namespace}.user.name;
in
{
  config = {
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
