{
  config,
  lib,
  namespace,
  pkgs,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.discord;
in
{
  options.${namespace}.apps.discord = with types; {
    enable = mkBoolOpt false "Whether or not to enable basic configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      discord
    ];
  };
}
