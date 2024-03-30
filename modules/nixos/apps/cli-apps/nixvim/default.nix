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
    environment.systemPackages = with pkgs; [less wyrdgard.neovim];
  };
}
