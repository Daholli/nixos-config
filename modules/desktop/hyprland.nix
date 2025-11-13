{
  flake.modules = {
    nixos.hyprland =
      {
        config,
        inputs,
        pkgs,
        ...
      }:
      let
        hyprland-package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

        focus-1password = pkgs.writeShellScriptBin "focus-or-open-1pass" ''
          running=$(hyprctl -j clients | jq -r '.[] | select(.class == "1password") | .workspace.id')

          if [[ $running != "" ]]; then
              hyprctl dispatch workspace $running
          else
              # always open on w/space 4
              hyprctl dispatch workspace 9
              ELECTRON_OZONE_PLATFORM_HINT=x11 1password&
          fi
        '';
      in
      {
        environment.systemPackages =
          with pkgs;
          [
            # Auth Agent
            hyprpolkitagent

            # Notification daemon
            libnotify

            # Wayland Utilities
            wlr-randr

            # Clipboard Stuff
            wl-clipboard
            xclip
            clipnotify
            # clipsync

            # Screenshot Utility
            grimblast

            # File Manager
            xfce.thunar

            # clean sddm theme
            elegant-sddm

            # json cli parser for bash script to focus 1password
            jq

            hyprpanel

            #####
            xdg-dbus-proxy
          ]
          ++ lib.optional config.programs._1password.enable focus-1password;

        programs = {
          hyprland = {
            enable = true;
            package = hyprland-package;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
            withUWSM = true;
          };
        };

        xdg = {
          autostart.enable = true;
          portal = {
            enable = true;
            extraPortals = [
              pkgs.xdg-desktop-portal
              pkgs.xdg-desktop-portal-gtk
            ];
            xdgOpenUsePortal = true;

            config = {
              common = {
                default = [ "*" ];
                "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
              };
              hyprland = {
                default = [
                  "hyprland"
                  "gtk"
                ];
                "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
                "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
              };
            };
          };
        };

        security.pam.services.gdm.enableGnomeKeyring = true;
        services.displayManager.gdm = {
          enable = true;
          wayland = true;
        };

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1"; # Hint electron apps to use wayland
          ELECTRON_OZONE_PLATFORM_HINT = "auto";

          XDG_SESSION_TYPE = "wayland";

          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORM = "wayland;xcb";
        };

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
        hyprland-package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      in
      {
        config = lib.mkIf osConfig.programs.hyprland.enable {
          wayland.windowManager.hyprland = {
            enable = true;
            package = hyprland-package;
            plugins = [ inputs.hy3.packages.${pkgs.stdenv.hostPlatform.system}.hy3 ];
            systemd.variables = [ "--all" ];
            settings = {
              "$mod" = "SUPER";

              exec-once = [
                "systemctl --user start hyprpolkitagent"

                "[workspace 1 silent] zen-beta"
                "[workspace 2 silent] steam"
                "[workspace 7 silent] obsidian"
                "[workspace 8 silent] discord"
                "[workspace 9 silent] ELECTRON_OZONE_PLATFORM_HINT=x11 1password" # fix for promts not showing up anymore
                "${pkgs.xorg.xhost}/bin/xhost +"

                "${lib.getExe pkgs.xorg.xrandr} --output DP-1 --primary"
              ];

              windowrulev2 = [
                #steam is a bit wierd, since it opens in multiple phases, so just move the last window to the workspace
                "workspace 2 silent, class:^(steam)$, title:^(Steam)"

                "workspace 7 silent, class:^(com.obsproject.Studio)$"
                "workspace 8 silent, class:^(steam)$, title:^(Friends List)"
                "workspace 8 silent, class:^(discord)$, title:^(Discord)"
              ];

              monitor = lib.mkIf (osConfig.networking.hostName == "yggdrasil") [
                #Ultrawide
                "DP-1,3440x1440@144, 0x0, 1"
                #Vertical
                "HDMI-A-1, 1920x1080@144, auto-right, 1, transform, 1"
              ];

              workspace = lib.mkIf (osConfig.networking.hostName == "yggdrasil") [
                "1, monitor:DP-1"
                "2, monitor:DP-1"
                "3, monitor:DP-1"
                "4, monitor:DP-1"
                "5, monitor:DP-1"
                "6, monitor:DP-1"
                "7, monitor:HDMI-A-1"
                "8, monitor:HDMI-A-1"
                "9, monitor:HDMI-A-1"
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

                shadow = {
                  enabled = true;
                  range = 100;
                  render_power = 2;
                  ignore_window = true;
                  color = "rgba(00000055)";
                  offset = "0 15";
                  scale = 0.97;
                };

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

              bind = [
                # compositor commands
                "$mod SHIFT, R, exec, hyprctl reload"
                "$mod SHIFT, Q, killactive,"
                "$mod SHIFT, E, exec, pkill Hyprland"
                "$mod CTRL, l, exec, hyprlock-blur"

                "$mod, F, fullscreen,"
                "$mod, G, togglegroup,"
                "$mod SHIFT, N, changegroupactive, f"
                "$mod SHIFT, P, changegroupactive, b"
                "$mod, R, togglesplit,"
                "$mod, T, togglefloating,"
                "$mod ALT, ,resizeactive,"

                "$mod CTRL, left, movecurrentworkspacetomonitor, l"
                "$mod CTRL, right, movecurrentworkspacetomonitor, r"

                # move focus
                "$mod, h, movefocus, l"
                "$mod, j, movefocus, d"
                "$mod, k, movefocus, u"
                "$mod, l, movefocus, r"
                "$mod, left, movefocus, l"
                "$mod, down, movefocus, d"
                "$mod, up, movefocus, u"
                "$mod, right, movefocus, r"

                # move focus
                "$mod SHIFT, h, movewindow, l, once"
                "$mod SHIFT, j, movewindow, d, once"
                "$mod SHIFT, k, movewindow, u, once"
                "$mod SHIFT, l, movewindow, r, once"
                "$mod SHIFT, left, movewindow, l, once"
                "$mod SHIFT, down, movewindow, d, once"
                "$mod SHIFT, up, movewindow, u, once"
                "$mod SHIFT, right, movewindow, r, once"

                #run important programs
                "$mod, Return, exec, kitty"
                "$mod, D, exec, fuzzel"
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
                      "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
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
            };
          };
        };
      };
  };
}
