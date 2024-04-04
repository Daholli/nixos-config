{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.discord;
in
{
  options.wyrdgard.apps.discord = with types; {
    enable = mkBoolOpt false "Whether or not to enable basic configuration";
  };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ discord ]; };
}
