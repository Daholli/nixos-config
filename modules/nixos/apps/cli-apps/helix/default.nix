{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.wyrdgard.apps.cli-apps.helix;
in
{
  options.wyrdgard.apps.cli-apps.helix = {
    enable = mkEnableOption "Whether to enable nixvim or not (Default true)";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ helix ];
    };

    wyrdgard.home = {
      extraOptions = {
        programs.helix = {
          enable = true;
          settings = {
            theme = "autumn_night_transparent";
            editor.cursor-shape = {
              normal = "block";
              insert = "bar";
              select = "underline";
            };
          };
          languages.language = [
            {
              name = "nix";
              auto-format = true;
              formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
            }
            {
              name = "rust";
              auto-format = true;
              formatter.command = "cargo fmt";
            }
          ];
          themes = {
            autumn_night_transparent = {
              "inherits" = "autumn_night";
              "ui.background" = { };
            };
          };
        };
      };
    };
  };
}
