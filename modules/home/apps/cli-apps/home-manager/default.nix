{
  lib,
  config,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.home-manager;
in {
  options.wyrdgard.apps.cli-apps.home-manager = {
    enable = mkBoolOpt true "Enable home-manager";
  };

  config = mkIf cfg.enable {
    programs.home-manager = enabled;
  };
}
