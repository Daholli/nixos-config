{
  flake.modules = {
    nixos."hosts/yggdrasil" =
      { inputs, ... }:
      {
        imports = [
          inputs.dank-greeter.nixosModules.default
        ];

        programs.dms-greeter = {
          enable = true;
          compositor = {
            name = "niri";
            customConfig = ''
              hotkey-overlay {
                  skip-at-startup
              }

              environment {
                  DMS_RUN_GREETER "1"
              }

              output "DP-1" {
                transform "normal"
                mode "3440x1440"
              }
            '';
          };

          configHome = "/home/cholli";
        };

        security = {
          pam = {
            services.greetd.enableGnomeKeyring = true;
          };
        };

        services.accounts-daemon.enable = true;
      };

    homeManager.cholli =
      {
        config,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      {
        config = lib.mkIf (osConfig.networking.hostName == "yggdrasil" && osConfig.programs.niri.enable) {
          home.packages = [ pkgs.kdePackages.dolphin ];

          programs.niri.settings = {
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

            workspaces = {
              "01-zen" = {
                open-on-output = "DP-1";
              };
              "02-games" = {
                open-on-output = "DP-1";
              };
              "03-work" = {
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

            # mkAfter so these land behind the shared rules in modules/desktop/niri.nix
            # -- niri applies window rules in order, last match wins.
            window-rules = lib.mkAfter [
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
                    app-id = "zen-beta";
                  }
                  {
                    app-id = "electron";
                    title = "Obsidian";
                    at-startup = true;
                  }
                  {
                    app-id = "obsidian";
                    title = "Obsidian";
                    at-startup = true;
                  }
                ];

                open-on-workspace = "01-zen";
              }
              {
                matches = [
                  {
                    app-id = "steam";
                    title = "Steam";
                  }
                ];

                open-on-workspace = "02-games";
              }
              {
                matches = [
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

                open-on-workspace = "02-games";
                default-column-width.proportion = 1.0;
                default-window-height.proportion = 1.0;
              }
              {
                matches = [
                  {
                    app-id = "element";
                  }
                  {
                    app-id = "electron";
                    title = "Element";
                  }
                  {
                    app-id = "vesktop";
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
                    app-id = "vesktop";
                  }
                  {
                    app-id = "Element";
                  }
                  {
                    app-id = "steam";
                    title = "Friends List.*";
                  }
                  {
                    app-id = "teams-for-linux";
                  }
                  {
                    title = "Microsoft Teams";
                    app-id = "electron";
                  }
                ];

                block-out-from = "screencast";
              }
            ];

            binds = with config.lib.niri; {
              "Mod+1".action = actions.focus-workspace "01-zen";
              "Mod+2".action = actions.focus-workspace "02-games";
              "Mod+3".action = actions.focus-workspace "03-work";
              "Mod+5".action = actions.focus-workspace "01-communication";
              "Mod+9".action = actions.focus-workspace "02-1password";
            };

            spawn-at-startup = [
              { argv = [ "zen-beta" ]; }
              { argv = [ "obsidian" ]; }
              { argv = [ "element-desktop" ]; }
              { argv = [ "vesktop" ]; }
              { argv = [ "1password" ]; }
              { sh = "sleep 1 && steam"; }
            ];
          };
        };
      };
  };
}
