{
  flake.modules = {
    nixos.niri =
      { inputs, pkgs, ... }:
      {
        imports = [
          inputs.niri-flake.nixosModules.niri
        ];

        programs.niri = {
          enable = true;
          package = inputs.niri-flake.packages.${pkgs.system}.niri-unstable;
        };

        environment.systemPackages = with pkgs; [
          kitty
          fuzzel

          inputs.niri-flake.packages.${pkgs.system}.xwayland-satellite-unstable

          wl-clipboard
          xsel

          mako
          waybar
        ];

        xdg = {
          autostart.enable = true;
          portal = {
            enable = true;
            extraPortals = [
              pkgs.xdg-desktop-portal-gnome
              pkgs.xdg-desktop-portal-gtk
            ];
            xdgOpenUsePortal = true;

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
        inputs,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      {
        config = lib.mkIf (osConfig.networking.hostName == "yggdrasil" && osConfig.programs.niri.enable) {

          programs.niri.settings = {
            prefer-no-csd = true;

            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                  rules = "escape:nocaps";
                };
                numlock = true;
              };

              touchpad = {
                enable = false;
              };
            };

            outputs."DP-1" = {
              mode = {
                width = 3440;
                height = 1440;
              };
            };
            outputs."HDMI-A-1" = {
              mode = {
                width = 1920;
                height = 1080;
              };
              transform.rotation = 90;
              # layout = {
              #   default-column-width.proportion = 1.0;
              # };
            };

            layout = {
              gaps = 5;
              center-focused-column = "never";

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

            hotkey-overlay.skip-at-startup = true;

            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

            # TODO: block 1pass from screenshots and window capture
            # TODO: move windows to workspaces where I expect them
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
              }
              {
                matches = [ { is-window-cast-target = true; } ];

                focus-ring = {
                  active.color = "#f38ba8";
                  inactive.color = "#7d0d2d";
                };

                border = {
                  inactive.color = "#7d0d2d";
                };

                shadow = {
                  color = "#7d0d2d70";
                };

                tab-indicator = {
                  active.color = "#f38ba8";
                  inactive.color = "#7d0d2d";
                };
              }
              {
                matches = [
                  {
                    app-id = "discord";
                  }
                  {
                    app-id = "1Password";
                  }
                  {
                    app-id = "steam";
                    title = "Friends List.*";
                  }
                ];
                open-on-output = "HDMI-A-1";
                default-column-width.proportion = 1.0;
              }
            ];

            binds =
              with config.lib.niri;
              lib.mkMerge [
                {
                  "Mod+Shift+Slash".action = actions.show-hotkey-overlay;
                  "Mod+Shift+E".action = actions.quit;
                  "Ctrl+Alt+Delete".action = actions.quit;

                  "Mod+Return".action.spawn = "${lib.getExe pkgs.kitty}";
                  "Mod+D".action.spawn = "${lib.getExe pkgs.fuzzel}";
                  "Mod+Alt+L".action.spawn = "hyprlock-blur";

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

                  "Mod+1".action = actions.focus-workspace "zen";
                  "Mod+2".action = actions.focus-workspace "steam";
                  "Mod+3".action = actions.focus-workspace "communication";
                  "Mod+4".action = actions.focus-workspace "work";

                  "Mod+J" = {
                    action = actions.focus-window-or-workspace-down;
                  };
                  "Mod+K" = {
                    action = actions.focus-window-or-workspace-up;
                  };
                  "Mod+Ctrl+J" = {
                    action = actions.move-window-down-or-to-workspace-down;
                  };
                  "Mod+Ctrl+K" = {
                    action = actions.move-window-up-or-to-workspace-up;
                  };
                  "Mod+Down" = {
                    action = actions.focus-window-or-workspace-down;
                  };
                  "Mod+Up" = {
                    action = actions.focus-window-or-workspace-up;
                  };
                  "Mod+Ctrl+Down" = {
                    action = actions.move-window-down-or-to-workspace-down;
                  };
                  "Mod+Ctrl+Up" = {
                    action = actions.move-window-up-or-to-workspace-up;
                  };

                  "Mod+H" = {
                    action = actions.focus-column-or-monitor-left;
                  };
                  "Mod+L" = {
                    action = actions.focus-column-or-monitor-right;
                  };
                  "Mod+Ctrl+H" = {
                    action = actions.move-column-left-or-to-monitor-left;
                  };
                  "Mod+Ctrl+L" = {
                    action = actions.move-column-right-or-to-monitor-right;
                  };
                  "Mod+Left" = {
                    action = actions.focus-column-or-monitor-left;
                  };
                  "Mod+Right" = {
                    action = actions.focus-column-or-monitor-right;
                  };
                  "Mod+Ctrl+Left" = {
                    action = actions.move-column-left-or-to-monitor-left;
                  };
                  "Mod+Ctrl+Right" = {
                    action = actions.move-column-right-or-to-monitor-right;
                  };

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
                  "Mod+Comma".action = actions.consume-window-into-column;
                  "Mod+Period".action = actions.expel-window-from-column;

                  "Mod+R".action = actions.switch-preset-column-width;
                  "Mod+Shift+R".action = actions.switch-preset-window-height;
                  "Mod+Ctrl+R".action = actions.reset-window-height;
                  "Mod+F".action = actions.fullscreen-window;
                  "Mod+Shift+F".action = actions.maximize-column;
                  "Mod+Ctrl+F".action = actions.expand-column-to-available-width;

                  "Mod+C".action = actions.center-column;
                  "Mod+V".action = actions.toggle-window-floating;

                  # Xwayland keyboard stuff
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

                  "XF86AudioRaiseVolume" = {
                    action.spawn = [
                      "wpctl"
                      "set-volume"
                      "@DEFAULT_AUDIO_SINK@"
                      "0.1+"
                    ];
                    allow-when-locked = true;
                  };
                  "XF86AudioLowerVolume" = {
                    action.spawn = [
                      "wpctl"
                      "set-volume"
                      "@DEFAULT_AUDIO_SINK@"
                      "0.1-"
                    ];
                    allow-when-locked = true;
                  };
                  "XF86AudioMute" = {
                    action.spawn = [
                      "wpctl"
                      "set-mute"
                      "@DEFAULT_AUDIO_SINK@"
                      "toggle"
                    ];
                    allow-when-locked = true;
                  };
                  "XF86AudioMicMute" = {
                    action.spawn = [
                      "wpctl"
                      "set-mute"
                      "@DEFAULT_AUDIO_SOURCE@"
                      "toggle"
                    ];
                    allow-when-locked = true;
                  };
                }
              ];

            spawn-at-startup = [
              { argv = [ "waybar" ]; }
              { argv = [ "zen-beta" ]; }
              { argv = [ "steam" ]; }
              { argv = [ "obsidian" ]; }
              { argv = [ "discord" ]; }
              { argv = [ "1password" ]; }
            ];

          };

        };
      };
  };
}
