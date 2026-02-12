{
  flake.modules = {
    homeManager.cholli =
      { lib, pkgs, ... }:
      {
        programs.zed-editor = {
          enable = true;

          userSettings = {
            auto_install_extensions = {
              nix = true;
              catppuccin = true;
              catppuccin-icons = true;
            };

            auto_update = false;

            base_keymap = "JetBrains";
            helix_mode = true;
            vim_mode = false;

            ui_font_family = "FiraCode Nerd Font";
            ui_font_size = 16;
            buffer_font_family = "FiraCode Nerd Font";
            buffer_font_size = 16;

            autosave = "on_focus_change";

            theme = {
              mode = "system";
              light = "Catppuccin Latte";
              dark = "Catppuccin Macchiato";
            };

            load_direnv = "shell_hook";
            terminal = {
              font_family = "FiraCode Nerd Font";
              font_size = 16;
            };

            agent = {
              enabled = true;

              default_model = {
                provider = "copilot_chat";
                model = "gpt-4o";
              };
            };

            agent_servers = {
              github-copilot = {
                type = "registry";
              };
            };

            edit_predictions.mode = "eager";
            features = {
              edit_prediction_provider = "copilot";
            };

            inlay_hints.enabled = true;
            lsp = {
              nixd = {
                binary = {
                  path = lib.getExe pkgs.nixd;
                };
              };
            };

          };

          userKeymaps = [
            {
              context = "Workspace";
              bindings = {
                "shift shift" = "file_finder::Toggle";
              };
            }
          ];
        };
      };
  };
}
