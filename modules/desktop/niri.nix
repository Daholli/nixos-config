{
  flake.modules = {
    nixos.niri =
      { inputs, pkgs, ... }:
      {
        programs.niri = {
          enable = true;
          package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
        };

        environment.systemPackages = with pkgs; [
          kitty

          inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable

          wl-clipboard
          xsel

          libnotify
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
        inputs,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      {
        config = lib.mkIf (osConfig.networking.hostName == "yggdrasil" && osConfig.programs.niri.enable) {
          catppuccin = {
            cursors = {
              enable = true;
            };
          };

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

            workspaces = {
              "01-zen" = {
                open-on-output = "DP-1";
              };
              "02-steam" = {
                open-on-output = "DP-1";
              };
              "03-work" = {
                open-on-output = "DP-1";
              };
              "04-games" = {
                open-on-output = "DP-1";
              };
              "01-communication" = {
                open-on-output = "HDMI-A-1";
              };
              "02-1password" = {
                open-on-output = "HDMI-A-1";
              };
            };

            layer-rules = [
              {
                matches = [ { namespace = "^dms:notification-popup$"; } ];
                block-out-from = "screencast";
              }
            ];

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

                #
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
              {
                matches = [
                  {
                    # This matches any subwindow of 1password e.g. the confirmation window for ssh keys
                    app-id = "1Password";
                    title = "1Password";
                    is-floating = true;
                  }
                ];

                # this works, the border is drawn correctly
                border = {
                  enable = true;
                  width = 2;
                  active.color = "#3a9657";
                  inactive.color = "#dbd11c";
                };

                #this does not seem to work
                open-focused = true;
                open-on-output = "DP-1";

              }
              {
                matches = [
                  {
                    app-id = "steam";
                    title = "Steam";
                  }
                ];

                open-on-workspace = "02-steam";
                open-maximized = true;
              }
              {
                matches = [
                  {
                    app-id = "obsidian";
                  }
                  {
                    app-id = "teams-for-linux";
                  }
                ];

                open-on-workspace = "03-work";
              }
              {
                matches = [
                  {
                    app-id = "steam_app_.*";
                  }
                  {
                    app-id = "factorio";
                  }
                  {
                    app-id = "dota2";
                  }
                ];

                open-on-workspace = "04-games";
                default-column-width.proportion = 1.0;
                default-window-height.proportion = 1.0;
                min-width = 3440;
                min-height = 1440;
              }
              {
                matches = [
                  {
                    app-id = "discord";
                  }
                  {
                    app-id = "steam";
                    title = "Friends List.*";
                  }
                ];
                open-on-workspace = "01-communication";
                default-column-width.proportion = 1.0;
                open-fullscreen = false;
              }
              {
                matches = [
                  {
                    app-id = "1password";
                    at-startup = true;
                  }
                ];

                open-on-workspace = "02-1password";
                default-column-width.proportion = 1.0;
                open-fullscreen = false;
              }
              {
                matches = [
                  {
                    app-id = "1Password";
                  }
                  {
                    app-id = "discord";
                  }
                  {
                    app-id = "steam";
                    title = "Friends List.*";
                  }
                  {
                    app-id = "teams-for-linux";
                  }
                ];

                block-out-from = "screencast";
              }
            ];

            binds =
              with config.lib.niri;
              lib.mkMerge [
                {
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

                  "Mod+1".action = actions.focus-workspace "01-zen";
                  "Mod+2".action = actions.focus-workspace "02-steam";
                  "Mod+3".action = actions.focus-workspace "03-work";
                  "Mod+4".action = actions.focus-workspace "04-games";
                  "Mod+5".action = actions.focus-workspace "01-communication";
                  "Mod+9".action = actions.focus-workspace "02-1password";

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

                  "Mod+R".action = actions.switch-preset-column-width;
                  "Mod+Shift+R".action = actions.switch-preset-window-height;
                  "Mod+Ctrl+R".action = actions.reset-window-height;
                  "Mod+F".action = actions.maximize-column;
                  "Mod+Shift+F".action = actions.fullscreen-window;
                  "Mod+Ctrl+F".action = actions.expand-column-to-available-width;

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
                }
              ];

            spawn-at-startup = [
              { argv = [ "zen-beta" ]; }
              { argv = [ "obsidian" ]; }
              { argv = [ "discord" ]; }
              { argv = [ "1password" ]; }
              { sh = "sleep 1 && steam"; }
            ];
          };

        };
      };
  };
}
