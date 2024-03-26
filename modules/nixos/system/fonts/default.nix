{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.system.fonts;
in {
  options.wyrdgard.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    environment.systemPackages = with pkgs; [
      font-manager
    ];

    fonts.packages = with pkgs;
      [
        (nerdfonts.override {fonts = ["CodeNewRoman" "NerdFontsSymbolsOnly"];})
        font-awesome
        powerline-fonts
        powerline-symbols
      ]
      ++ cfg.fonts;
  };
}
