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
  cfg = config.wyrdgard.system.hardware.networking;
in
{
  options.wyrdgard.system.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking";
  };

  config = mkIf cfg.enable { networking.networkmanager.enable = true; };
}
