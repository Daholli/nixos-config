{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.system.time;
in {
  options.wyrdgard.system.time = with types; {
    enable =
      mkBoolOpt false "Whether or not to configure timezone information.";
  };

  config = mkIf cfg.enable {
    time.timeZone = "Europe/Berlin";
  };
}
