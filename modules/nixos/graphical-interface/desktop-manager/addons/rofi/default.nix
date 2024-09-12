{
  config,
  namespace,
  options,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.${namespace}.graphical-interface.desktop-manager.addons.rofi;

  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.${namespace}.graphical-interface.desktop-manager.addons.rofi = {
    enable = mkEnableOption "Rofi";
    package = mkOption {
      type = types.package;
      default = pkgs.rofi;
      description = "The package to use for Rofi";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    wyrdgard.home.file = {
      ".config/rofi/config.rasi".source = ./config.rasi;
    };
  };
}
