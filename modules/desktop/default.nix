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
        zenbrowser = inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default;
      in

      {
        environment = {
          systemPackages = with pkgs; [
            zenbrowser

            sourcegit

            (pkgs.catppuccin-kvantum.override {
              accent = "lavender";
              variant = "mocha";
            })
            pkgs.adwaita-icon-theme
          ];

          sessionVariables = {
            DEFAULT_BROWSER = "${zenbrowser}/bin/zen-beta";
            BROWSER = "zen-beta";

            QT_QPA_PLATFORMTHEME = "kvantum";
            QS_ICON_THEME = "adwaita";
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
        # dconf = {
        #   settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
        # };

        # gtk = {
        #   enable = true;
        #   theme = {
        #     name = "Adwaita-dark";
        #     package = pkgs.gnome-themes-extra;
        #   };
        # };

        qt = {
          enable = true;
          platformTheme.name = "qtct";
          style = {
            package = (
              pkgs.catppuccin-kvantum.override {
                accent = "lavender";
                variant = "mocha";
              }
            );
            name = "kvantum";
          };
        };

        systemd.user.sessionVariables = osConfig.home-manager.users.cholli.home.sessionVariables;

      };
  };
}
