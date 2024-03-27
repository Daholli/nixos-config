{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.nixvim;
in {
  options.wyrdgard.apps.cli-apps.nixvim = with types; {
    enable = mkBoolOpt true "Whether to enable nixvim or not (Default true)";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      colorschemes.tokyonight = enabled;
      globals.mapleader = " ";

      clipboard.providers.wl-copy = enabled;

      options = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
      };
      
      
    };
  };
}
