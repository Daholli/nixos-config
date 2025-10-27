{
  flake.modules = {
    nixos.desktop =
      {
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      let
        zenbrowser = inputs.zen-browser.packages."${pkgs.system}".default;
      in

      {
        environment = {
          systemPackages = [
            zenbrowser
          ];

          sessionVariables = {
            DEFAULT_BROWSER = "${zenbrowser}/bin/zen-beta";
            BROWSER = "zen-beta";
          };

          etc = lib.mkIf config.programs._1password.enable {
            "1password/custom_allowed_browsers" = {
              text = ''
                zen
              '';
              mode = "0755";
            };
          };
        };
      };

    homeManager.cholli =
      { pkgs, osConfig, ... }:
      {
        dconf = {
          settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
        };

        gtk = {
          enable = true;
          theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };
        };

        # qt = {
        #   enable = true;
        #   platformTheme.name = "gnome";
        #   style.name = "adwaita-dark";
        # };

        systemd.user.sessionVariables = osConfig.home-manager.users.cholli.home.sessionVariables;

      };
  };
}
