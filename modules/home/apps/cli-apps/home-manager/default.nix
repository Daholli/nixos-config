{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.wyrdgard) enabled;

  cfg = config.wyrdgard.apps.cli-apps.home-manager;
in {
  options.wyrdgard.apps.cli-apps.home-manager = {
    enable = mkEnableOption "home-manager";
  };

  config = mkIf cfg.enable {
    programs.home-manager = enabled;
  };
}
