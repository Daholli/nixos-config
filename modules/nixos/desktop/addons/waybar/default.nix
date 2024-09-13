{
  lib,
  config,
  options,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.addons.waybar;

  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options.${namespace}.desktop.addons.waybar = {
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
