{
  flake.modules = {
    nixos.desktop =
      { pkgs, ... }:
      let
        hyprlock-blur = pkgs.writeShellScriptBin "hyprlock-blur" ''
          ${pkgs.grim}/bin/grim -o DP-1 -l 0 /tmp/screenshot1.png &
          ${pkgs.grim}/bin/grim -o HDMI-A-1 -l 0 /tmp/screenshot2.png & 
          wait &&
          hyprlock 
        '';
      in
      {
        security.pam.services.hyprlock = {
          allowNullPassword = false;
          startSession = false;
          text = ''
            auth    include login
            account include login
          '';
        };

        environment.systemPackages = [ hyprlock-blur ];

      };

    homeManager.cholli =
      {
        inputs,
        lib,
        pkgs,
        osConfig,
        ...
      }:
      let
        hyprlock-package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;
      in
      {
        config = lib.mkIf osConfig.programs.hyprland.enable {
          programs.hyprlock = {
            enable = true;
            package = hyprlock-package;
            settings = {
              # inspiration from https://github.com/justinmdickey/publicdots/blob/main/.config/hypr/hyprlock.conf
              background = [
                {
                  monitor = "DP-1";
                  path = "/tmp/screenshot1.png";

                  blur_passes = 1; # 0 disables blurring
                  blur_size = 7;
                  noise = 1.17e-2;
                }
                {
                  monitor = "HDMI-A-1";
                  path = "/tmp/screenshot2.png";

                  blur_passes = 2; # 0 disables blurring
                  blur_size = 7;
                  noise = 1.17e-2;
                }
              ];

              label = [
                {
                  monitor = "DP-1";
                  text = "$TIME";
                  color = "rgba(242, 243, 244, 0.75)";
                  font_size = 95;
                  font_family = "JetBrains Mono";
                  position = "0, 300";
                  halign = "center";
                  valign = "center";
                }
                {

                  monitor = "DP-1";
                  text = ''cmd[update:1000] echo $(date +"%A, %B %d")'';
                  color = "rgba(242, 243, 244, 0.75)";
                  font_size = 22;
                  font_family = "JetBrains Mono";
                  position = "0, 200";
                  halign = "center";
                  valign = "center";

                }
              ];

              image = {
                monitor = "DP-1";
                path = "/home/cholli/Pictures/profile.png";

                position = "0, 50";
                halign = "center";
                valign = "center";
              };

              input-field = {
                monitor = "DP-1";
                size = "200,50";
                outline_thickness = 2;
                dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
                dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
                dots_center = true;
                outer_color = "rgba(0, 0, 0, 0)";
                inner_color = "rgba(0, 0, 0, 0.2)";
                font_color = "rgb(111, 45, 104)";
                fade_on_empty = false;
                rounding = -1;
                check_color = "rgb(30, 107, 204)";
                placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
                hide_input = false;
                position = "0, -100";
                halign = "center";
                valign = "center";
              };

              general = {
                auth_method = "pam";
              };
            };
          };
        };
      };
  };
}
