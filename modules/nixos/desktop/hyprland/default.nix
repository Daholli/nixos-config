{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  ...
}:
with lib.${namespace};
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkMerge
    types
    ;
  cfg = config.${namespace}.desktop.hyprland;

  cachix-url = "https://hyprland.cachix.org";
  cachix-key = "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=";

  hyprland-package = inputs.hyprland.packages.${system}.hyprland;

  focus-1password = pkgs.writeShellScriptBin "focus-or-open-1pass" ''
    running=$(hyprctl -j clients | jq -r '.[] | select(.class == "1password") | .workspace.id')

    if [[ $running != "" ]]; then
        hyprctl dispatch workspace $running
    else
        # always open on w/space 4
        hyprctl dispatch workspace 4
        1password&
    fi
  '';
in
{
  options.${namespace}.desktop.hyprland = {
    enable = mkEnableOption "Whether to enable hyprland";
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional Hyprland settings to apply.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      polkit-kde-agent

      wl-clipboard
      wl-screenrec
      wlr-randr
      grimblast
      xfce.thunar
      dunst

      elegant-sddm

      jq
      focus-1password
    ];

    programs = {
      hyprland = {
        enable = true;
        package = hyprland-package;
        portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
      };
    };

    services = {
      xserver = enabled;
      displayManager.sddm = {
        enable = true;
        theme = "Elegant";
      };
    };

    ${namespace} = {
      desktop.addons = {
        waybar = enabled;
        rofi = {
          enable = true;
          package = pkgs.rofi-wayland-unwrapped;
        };
        hyprlock = enabled;
        hyprpaper = enabled;
      };

      nix.extra-substituters.${cachix-url} = {
        key = cachix-key;
      };

      home.extraOptions = {
        wayland.windowManager.hyprland = {
          enable = true;
          package = hyprland-package;
          plugins = [ inputs.hy3.packages.${system}.hy3 ];
          settings = mkMerge [
            {
              "$mod" = "SUPER";

              env = [
                "QT_AUTO_SCREEN_SCALE_FACTOR,1"
                "QT_QPA_PLATFORM,wayland;xcb"
                "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
              ];

              exec-once = [
                "hyprpaper"
                "waybar"
                "dunst"
                "systemctl --user start plasma-polkit-agent"

                "[workspace 3 silent] steam"
                "[workspace 2 silent] discord"
                "[workspace 4 silent] 1password"
                "[workspace 1 silent] zen"
              ];

              windowrulev2 = [
                #stean is a bit wierd, since it opens in multiple phases, so just move the last window to the workspace
                "workspace 3 silent, class:^(steam)$, title:^(Steam)"

                # make xwaylandvideobridge window invisible
                "opacity 0.0 override, class:^(xwaylandvideobridge)$"
                "noanim, class:^(xwaylandvideobridge)$"
                "noinitialfocus, class:^(xwaylandvideobridge)$"
                "maxsize 1 1, class:^(xwaylandvideobridge)$"
                "noblur, class:^(xwaylandvideobridge)$"
              ];

              general = {
                layout = "hy3";
                gaps_in = 5;
                gaps_out = 5;
                border_size = 1;
                "col.active_border" = "rgba(88888888)";
                "col.inactive_border" = "rgba(00000088)";

                allow_tearing = true;
                resize_on_border = true;
              };

              misc = {
                # hyprchan
                force_default_wallpaper = 2;
                # focus new windows that want to be focused
                focus_on_activate = true;
              };

              decoration = {
                rounding = 16;
                blur = {
                  enabled = true;
                  brightness = 1.0;
                  contrast = 1.0;
                  noise = 1.0e-2;

                  vibrancy = 0.2;
                  vibrancy_darkness = 0.5;

                  passes = 4;
                  size = 7;

                  popups = true;
                  popups_ignorealpha = 0.2;
                };

                drop_shadow = true;
                shadow_ignore_window = true;
                shadow_offset = "0 15";
                shadow_range = 100;
                shadow_render_power = 2;
                shadow_scale = 0.97;
                "col.shadow" = "rgba(00000055)";
              };

              animations = {
                enabled = true;
                animation = [
                  "border, 1, 2, default"
                  "fade, 1, 4, default"
                  "windows, 1, 3, default, popin 80%"
                  "workspaces, 1, 2, default, slide"
                ];
              };

              bind =
                [
                  # compositor commands
                  "$mod SHIFT, R, exec, hyprctl reload"
                  "$mod SHIFT, Q, killactive,"
                  "$mod SHIFT, E, exec, pkill Hyprland"

                  "$mod, F, fullscreen,"
                  "$mod, G, togglegroup,"
                  "$mod SHIFT, N, changegroupactive, f"
                  "$mod SHIFT, P, changegroupactive, b"
                  "$mod, R, togglesplit,"
                  "$mod, T, togglefloating,"
                  "$mod, P, pseudo,"
                  "$mod ALT, ,resizeactive,"

                  "$mod CTRL, left, movecurrentworkspacetomonitor, l"
                  "$mod CTRL, right, movecurrentworkspacetomonitor, r"

                  # move focus
                  "$mod, h, hy3:movefocus, l"
                  "$mod, j, hy3:movefocus, d"
                  "$mod, k, hy3:movefocus, u"
                  "$mod, l, hy3:movefocus, r"
                  "$mod, left, hy3:movefocus, l"
                  "$mod, down, hy3:movefocus, d"
                  "$mod, up, hy3:movefocus, u"
                  "$mod, right, hy3:movefocus, r"

                  # move focus
                  "$mod SHIFT, h, hy3:movewindow, l, once"
                  "$mod SHIFT, j, hy3:movewindow, d, once"
                  "$mod SHIFT, k, hy3:movewindow, u, once"
                  "$mod SHIFT, l, hy3:movewindow, r, once"
                  "$mod SHIFT, left, hy3:movewindow, l, once"
                  "$mod SHIFT, down, hy3:movewindow, d, once"
                  "$mod SHIFT, up, hy3:movewindow, u, once"
                  "$mod SHIFT, right, hy3:movewindow, r, once"

                  #run important programs
                  "$mod, Return, exec, kitty"
                  "$mod, Z, exec, zen"
                  "$mod, D, exec, rofi -show drun"
                  "$mod, P, exec, focus-or-open-1pass"
                  # "$mod, D, exec, rofi -show combi"

                  #screenshot
                  ", Print, exec, grimblast copy area"
                ]
                ++ (
                  # workspaces
                  # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
                  builtins.concatLists (
                    builtins.genList (
                      i:
                      let
                        ws = i + 1;
                      in
                      [
                        "$mod, code:1${toString i}, workspace, ${toString ws}"
                        "$mod SHIFT, code:1${toString i}, hy3:movetoworkspace, ${toString ws}"
                      ]
                    ) 9
                  )
                );

              # mouse movements
              bindm = [
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
                "$mod ALT, mouse:272, resizewindow"
              ];

              bindl = [
                # volume
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ];

              bindle = [
                # volume
                ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
                ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"
              ];

              input = {
                kb_layout = "us";

                # focus change on cursor move
                follow_mouse = 2;
                force_no_accel = 1;
                accel_profile = "flat";
              };

              plugin = {
                hy3 = {
                  autotile = {
                    enable = true;
                    trigger_width = 800;
                    trigger_height = 500;
                  };
                };
              };
            }
            cfg.settings
          ];

        };

      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
