{
  config,
  lib,
  namespace,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.hardware.networking;
in
{
  options.${namespace}.system.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking";
  };

  config = mkIf cfg.enable { networking.networkmanager.enable = true; };
}
