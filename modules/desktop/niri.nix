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

        environment.systemPackages = [
          pkgs.alacritty
          pkgs.fuzzel
        ];
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

        config = lib.mkIf (osConfig.networking.hostName == "yggdrasil") {
          programs.niri.settings = {
            input = {
              keyboard = {
                numlock = true;
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

            # block 1pass from screenshots and window capture
            window-rules = [
            ];

            binds =
              with config.lib.niri;
              let
                workspaces = (builtins.genList (x: x + 1) 9);

                focus-workspaces = builtins.listToAttrs (
                  map (num: {
                    name = "Mod+${toString num}";
                    value = {
                      action.focus-workspace = num;
                    };
                  }) workspaces
                );
              in

              lib.mkMerge [
                {
                  "Mod+Shift+Slash".action = actions.show-hotkey-overlay;

                  "Mod+Return".action.spawn = "${lib.getExe pkgs.kitty}";
                  "Mod+D".action.spawn = "${lib.getExe pkgs.fuzzel}";
                  "Mod+Alt+L".action.spawn = "hyprlock-blur";

                  "Mod+Shift+Q" = {
                    action = actions.close-window;
                    repeat = false;
                  };

                  "Mod+O" = {
                    action = actions.toggle-overview;
                    repeat = false;
                  };

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
                focus-workspaces
              ];

          };

        };
      };
  };
}
