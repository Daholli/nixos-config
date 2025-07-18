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
  inherit (lib) mkIf mkEnableOption mkOption;
  cfg = config.${namespace}.apps.cli-apps.helix;

  cachix-url = "https://helix.cachix.org";
  cachix-key = "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=";

  helix-pkg = inputs.helix.packages.${system}.default;
in
{
  options.${namespace}.apps.cli-apps.helix = {
    enable = mkEnableOption "Whether to enable helix or not";
    pkg = mkOption {
      type = lib.types.package;
      default = helix-pkg;
      description = "Which helix pacakge to use";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [
        cfg.pkg
      ];
    };

    ${namespace} = {
      home.extraOptions = {
        home.file.".config/helix/ignore".text = ''
          .idea/
          !**/appsettings.json
          .direnv/
          .devenv/
        '';

        catppuccin.helix.enable = true;

        programs.helix = {
          enable = true;
          package = helix-pkg;
          defaultEditor = true;
          settings = {
            editor = {
              auto-format = true;
              line-number = "relative";
              file-picker = {
                hidden = false;
              };

              lsp = {
                display-inlay-hints = true;
                display-messages = true;
              };

              cursor-shape = {
                normal = "block";
                insert = "bar";
                select = "underline";
              };

              indent-guides = {
                render = true;
                character = "|";
              };

              statusline = {
                left = [
                  "mode"
                  "spinner"
                ];
                center = [ "file-name" ];
                right = [
                  "workspace-diagnostics"
                  "diagnostics"
                  "selections"
                  "position"
                  "total-line-numbers"
                  "spacer"
                  "file-encoding"
                  "file-line-ending"
                  "file-type"
                ];
                separator = "│";
              };
            };

            keys = {
              normal = {
                esc = [
                  "collapse_selection"
                  "keep_primary_selection"
                ];
                space = {
                  space = "file_picker";
                };

                C-j = (builtins.genList (_: "move_line_down") 5) ++ [ "align_view_center" ];
                C-k = (builtins.genList (_: "move_line_up") 5) ++ [ "align_view_center" ];
              };
            };
          };

          languages = {
            language = [
              {
                name = "nix";
                auto-format = true;
                formatter.command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
                language-servers = [
                  "nixd"
                  "nil"
                ];
              }
              {
                # provided by the dev environment in the rust shell
                name = "rust";
                auto-format = true;
                formatter.command = "cargo fmt";
                language-servers = [ "rust-analyzer" ];
              }
            ];

            language-server = {
              nixd = {
                command = "${pkgs.nixd}/bin/nixd";
              };
              marksman = {
                command = "${pkgs.marksman}/bin/marksman";
              };
              vscode-json-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
                args = [ "--stdio" ];
                config.provideFormatter = true;
                config.json.validate.enable = true;
              };
              vscode-html-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
                args = [ "--stdio" ];
                config.provideFormatter = true;
              };
              vscode-css-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
                args = [ "--stdio" ];
                config.provideFormatter = true;
              };
              vscode-eslint-language-server = {
                command = "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
                args = [ "--stdio" ];
                config.provideFormatter = true;
              };
            };
          };
        };
      };

      nix.extra-substituters.${cachix-url} = {
        key = cachix-key;
      };
    };
  };
}
