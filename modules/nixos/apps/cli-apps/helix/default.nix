{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.wyrdgard.apps.cli-apps.helix;

  cachix-url = "https://helix.cachix.org";
  cachix-key = "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=";

  helix-pkg = inputs.helix.packages.${system}.default;
in
{
  options.wyrdgard.apps.cli-apps.helix = {
    enable = mkEnableOption "Whether to enable nixvim or not";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ helix-pkg ];
    };

    wyrdgard = {
      home = {
        extraOptions = {
          programs.helix = {
            enable = true;
            package = helix-pkg;
            defaultEditor = true;
            settings = {
              theme = "tokyonight";
              editor = {
                line-number = "relative";

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
                  space = {
                    space = "file_picker";
                  };

                  C-j = [
                    "move_line_down"
                    "move_line_down"
                    "move_line_down"
                    "move_line_down"
                    "move_line_down"
                  ];
                  C-k = [
                    "move_line_up"
                    "move_line_up"
                    "move_line_up"
                    "move_line_up"
                    "move_line_up"
                  ];
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
                nil = {
                  command = "${pkgs.nil}/bin/nil";
                };
                nixd = {
                  command = "${pkgs.nixd}/bin/nixd";
                };
                marksman = {
                  command = "${pkgs.marksman}/bin/marksman";
                };
                omnisharp = {
                  command = "${pkgs.omnisharp-roslyn}/bin/OmniSharp";
                };
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
