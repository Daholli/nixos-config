{
  flake.modules = {
    nixos.niri =
      { inputs, pkgs, ... }:
      {
        programs.niri = {
          enable = true;
          package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
        };

        environment.systemPackages = [
          pkgs.kitty

          inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable

          pkgs.wl-clipboard
          pkgs.xsel

          pkgs.libnotify
        ];

        xdg = {
          autostart.enable = true;
          portal = {
            enable = true;
            extraPortals = [
              pkgs.xdg-desktop-portal-gnome
              pkgs.xdg-desktop-portal-gtk
            ];

            config = {
              common = {
                default = [ "*" ];
                "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
              };
              niri = {
                default = [
                  "gnome"
                  "gtk"
                ];
                "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
                "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
              };
            };
          };
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
        config,
        lib,
        osConfig,
        ...
      }:
      {
        config = lib.mkIf osConfig.programs.niri.enable {
          home.pointerCursor.enable = true;
          catppuccin.cursors.enable = true;

          programs.niri.settings = {
            prefer-no-csd = true;

            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  options = "caps:escape";
                };
                numlock = true;
              };

              touchpad = {
                enable = false;
              };
            };

            layout = {
              gaps = 5;
              center-focused-column = "on-overflow";
              always-center-single-column = true;

              default-column-width = {
                proportion = 0.5;
              };

              preset-column-widths = [
                { proportion = 1. / 3.; }
                { proportion = 1. / 2.; }
                { proportion = 2. / 3.; }
              ];

              focus-ring = {
                width = 1;
                active = {
                  color = "#7fc8ff";
                };
                inactive = {
                  color = "#505050";
                };
              };
            };

            cursor = {
              hide-when-typing = true;
              hide-after-inactive-ms = 10000;
            };

            hotkey-overlay.skip-at-startup = true;

            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

            window-rules = [
              {
                excludes = [ ];
                clip-to-geometry = true;
                geometry-corner-radius = {
                  top-left = 15.0;
                  top-right = 15.0;
                  bottom-left = 15.0;
                  bottom-right = 15.0;
                };

                open-fullscreen = false;
              }
              {
                matches = [ { is-window-cast-target = true; } ];

                border = {
                  enable = true;
                  width = 2;
                  active.color = "#f38ba8";
                  inactive.color = "#f38ba8";
                };

                shadow = {
                  color = "#f38ba870";
                };
              }
            ];

            binds = with config.lib.niri; {
              "Mod+Shift+Slash".action = actions.show-hotkey-overlay;
              "Mod+Shift+E".action = actions.quit;
              "Ctrl+Alt+Delete".action = actions.quit;

              "Mod+Return".action.spawn = "${lib.getExe config.programs.kitty.package}";

              "Mod+Escape" = {
                allow-inhibiting = false;
                action = actions.toggle-keyboard-shortcuts-inhibit;
              };

              "Print".action.screenshot = [ ];
              "Ctrl+Print".action.screenshot-screen = [ ];
              "Alt+Print".action.screenshot-window = [ ];

              "Mod+Shift+Q" = {
                action = actions.close-window;
                repeat = false;
              };

              "Mod+O" = {
                action = actions.toggle-overview;
                repeat = false;
              };

              "Mod+J".action = actions.focus-window-or-workspace-down;
              "Mod+K".action = actions.focus-window-or-workspace-up;
              "Mod+Ctrl+J".action = actions.move-window-down-or-to-workspace-down;
              "Mod+Ctrl+K".action = actions.move-window-up-or-to-workspace-up;
              "Mod+Down".action = actions.focus-window-or-workspace-down;
              "Mod+Up".action = actions.focus-window-or-workspace-up;
              "Mod+Ctrl+Down".action = actions.move-window-down-or-to-workspace-down;
              "Mod+Ctrl+Up".action = actions.move-window-up-or-to-workspace-up;

              "Mod+H".action = actions.focus-column-or-monitor-left;
              "Mod+L".action = actions.focus-column-or-monitor-right;
              "Mod+Ctrl+H".action = actions.move-column-left-or-to-monitor-left;
              "Mod+Ctrl+L".action = actions.move-column-right-or-to-monitor-right;
              "Mod+Left".action = actions.focus-column-or-monitor-left;
              "Mod+Right".action = actions.focus-column-or-monitor-right;
              "Mod+Ctrl+Left".action = actions.move-column-left-or-to-monitor-left;
              "Mod+Ctrl+Right".action = actions.move-column-right-or-to-monitor-right;

              "Mod+WheelScrollDown" = {
                action = actions.focus-column-right;
              };
              "Mod+WheelScrollUp" = {
                action = actions.focus-column-left;
              };
              "Mod+Shift+WheelScrollDown" = {
                action = actions.focus-workspace-down;
                cooldown-ms = 150;
              };
              "Mod+Shift+WheelScrollUp" = {
                action = actions.focus-workspace-up;
                cooldown-ms = 150;
              };

              # Window Sizes
              "Mod+BracketLeft".action = actions.consume-or-expel-window-left;
              "Mod+BracketRight".action = actions.consume-or-expel-window-right;

              "Mod+R".action = actions.switch-preset-column-width;
              "Mod+Shift+R".action = actions.switch-preset-window-height;
              "Mod+Ctrl+R".action = actions.reset-window-height;
              "Mod+G".action = actions.toggle-window-floating;
              "Mod+F".action = actions.maximize-column;
              "Mod+Shift+F".action = actions.fullscreen-window;
              "Mod+Ctrl+F".action = actions.expand-column-to-available-width;

              # Xwayland clipboard bridge (xwayland-satellite on yggdrasil,
              # WSLg's X server on WSL).
              "Mod+Shift+C".action = actions.spawn [
                "sh"
                "-c"
                "env DISPLAY=:0 xsel -ob | wl-copy"
              ];
              "Mod+Shift+V".action = actions.spawn [
                "sh"
                "-c"
                "wl-paste -n | env DISPLAY=:0 xsel -ib"
              ];
            };
          };
        };
      };
  };
}
