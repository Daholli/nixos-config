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
  inherit (lib.wyrdgard) enabled;
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

    services.upower = enabled;
    fonts.packages = with pkgs; [
      cascadia-code
      jetbrains-mono
      maple-mono-NF
      material-design-icons
      noto-fonts-cjk-sans
    ];

    wyrdgard.home.file = {
      ".config/waybar/config.jsonc".source = ./config.jsonc;
      ".config/waybar/style.css".source = ./style.css;
    };
  };
}
