{
  lib,
  config,
  options,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.graphical-interface.desktop-manager.addons.waybar;

  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.${namespace}.graphical-interface.desktop-manager.addons.waybar = {
    enable = mkEnableOption "Waybar";
    package = mkOption {
      type = types.package;
      default = pkgs.waybar;
      description = "The package to use for Waybar";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];


    wyrdgard.home.file = {
      ".config/waybar/config".source = ./config;
      ".config/waybar/style.css".source = ./style.css;
    };
  };
}
