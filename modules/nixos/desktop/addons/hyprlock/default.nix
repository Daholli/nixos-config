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
  inherit (lib.${namespace}) enabled;

  hyprlock-package = inputs.hyprlock.packages.${system}.hyprlock;

  hyprlock-blur = pkgs.writeShellScriptBin "hyprlock-blur" ''
    ${pkgs.grim}/bin/grim -o DP-2 -l 0 /tmp/screenshot1.png &
    ${pkgs.grim}/bin/grim -o HDMI-A-1 -l 0 /tmp/screenshot2.png & 
    wait &&
    hyprlock 
  '';

  cfg = config.${namespace}.desktop.addons.hyprlock;
in
{
  options.${namespace}.desktop.addons.hyprlock = {
    enable = mkEnableOption "Enable Hyprlock";
  };

  config = mkIf cfg.enable {
    security.pam.services.hyprlock = { };

    ${namespace}.desktop.hyprland.settings = {
      bind = [
        "$mod CTRL, l, exec, ${hyprlock-blur}/bin/hyprlock-blur"
      ];
    };

    snowfallorg.users.${config.${namespace}.user.name}.home.config = {

      programs.hyprlock = {
        enable = true;
        package = hyprlock-package;
        settings = {
          background = [
            {
              monitor = "DP-2";
              path = "/tmp/screenshot1.png";

              # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
              blur_passes = 1; # 0 disables blurring
              blur_size = 7;
              noise = 1.17e-2;
            }
            {
              monitor = "HDMI-A-1";
              path = "/tmp/screenshot2.png";

              # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
              blur_passes = 2; # 0 disables blurring
              blur_size = 7;
              noise = 1.17e-2;
            }
          ];

          input-field = {
            monitor = "DP-2";
            size = "200,50";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.2)";
            font_color = "rgb(255,129,0)";
            fade_on_empty = false;
            rounding = -1;
            check_color = "rgb(204, 136, 34)";
            placeholder_text = ''<i><span foreground="##cdd6f4">Input Password...</span></i>'';
            hide_input = false;
            position = "0, -100";
            halign = "center";
            valign = "center";
          };

          label = [
            {
              monitor = "DP-2";
              text = "$TIME";
              color = "rgba(242, 243, 244, 0.75)";
              font_size = 95;
              font_family = "JetBrains Mono";
              position = "0, 300";
              halign = "center";
              valign = "center";
            }
            {

              monitor = "DP-2";
              text = ''cmd[update:1000] echo $(date +"%A, %B %d")'';
              color = "rgba(242, 243, 244, 0.75)";
              font_size = 22;
              font_family = "JetBrains Mono";
              position = "0, 200";
              halign = "center";
              valign = "center";

            }
          ];
        };
      };
    };

    # ${namespace}.home.extraOptions = {
    #   programs.hello = enabled;

    #   programs.hyprlock = {
    #     enable = true;
    #     settings = {
    #       monitor = "DP-2";
    #     };
    #   };
    # };
  };
}
