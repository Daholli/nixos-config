{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.teamspeak;
in
{
  options.wyrdgard.apps.teamspeak = with types; {
    enable = mkBoolOpt false "Whether or not to enable basic configuration";
  };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ teamspeak_client ]; };
}
