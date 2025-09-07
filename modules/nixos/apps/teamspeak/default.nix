{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.teamspeak;
in
{
  options.${namespace}.apps.teamspeak = with types; {
    enable = mkBoolOpt false "Whether or not to enable basic configuration";
  };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ teamspeak6-client ]; };
}
