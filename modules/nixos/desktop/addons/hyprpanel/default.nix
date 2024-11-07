{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkMerge
    mkOption
    literalExpression
    ;

  cfg = config.${namespace}.desktop.addons.hyprpanel;

  settingsFormat = pkgs.formats.json { };
  settings = {
    bar = {
      layouts = {
        "0" = {
          left = [
            "workspaces"
          ];
          middle = [
            "windowtitle"
          ];
        };
      };
    };
  };
in
{
  options.${namespace}.desktop.addons.hyprpanel = {
    enable = mkEnableOption "Enable HyprIdle";
    extraSettings = mkOption {
      default = { };
      inherit (settingsFormat) type;
      description = ''
        Additional Options to pass to hyprpanel
      '';
      example = literalExpression ''
        {
          
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    ${namespace}.home.file = {
      ".cache/ags/options_test.json".source = settingsFormat.generate "options.json" mkMerge [
        settings
        cfg.extraSettings
      ];
    };
  };
}
