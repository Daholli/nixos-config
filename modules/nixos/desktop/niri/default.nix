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

  cfg = config.${namespace}.desktop.niri;

  apps-submodule = types.submodule {
    options = {
      terminal = mkOption {
        type = types.package;
        default = pkgs.kitty;
        description = "The default Terminal to use";
      };
      runner = mkOption {
        type = types.package;
        default = pkgs.fuzzel;
        description = "The app-runner to use";
      };
    };
  };

in
{
  options.${namespace}.desktop.niri = {
    enable = mkEnableOption "Whether to enable niri";
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional niri settings to apply.";
    };
    apps = mkOption {
      type = apps-submodule;
      default = { };
      description = "Which apps to use";
    };
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = inputs.niri-flake.packages.${system}.niri-unstable;
    };

    environment.systemPackages = [
      pkgs.alacritty
      pkgs.fuzzel
    ];

    ${namespace} = {
      desktop.addons = {
        hyprlock = enabled;
        hypridle = enabled;
      };
    };

    snowfallorg.users."cholli".home.config = {
      programs.niri.settings = mkMerge [
        {
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
                  name = "Mod=${toString num}";
                  value = {
                    action.focus-workspace = num;
                  };
                }) workspaces
              );
            in

            mkMerge [
              {
                "Mod+Shift+Slash".action = show-hotkey-overlay;

                "Mod+Enter".action.spawn = "${lib.getExe cfg.apps.terminal}";
                "Mod+D".action.spwan = "${lib.getExe cfg.apps.runner}";
                "Mod+Alt+L".action.spawn = "hyprlock-blur";

                "Mod+Shift+Q" = {
                  action = actions.close-window;
                  repeat = false;
                };

                "Mod+O" = {
                  action = actions.toggle-overview;
                  repeat = false;
                };

                inherit focus-workspaces;

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

        }
        cfg.settings
      ];
    };
  };
}
