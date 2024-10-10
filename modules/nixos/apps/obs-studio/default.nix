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
  cfg = config.${namespace}.apps.obs-studio;
in
{
  options.${namespace}.apps.obs-studio = with types; {
    enable = mkBoolOpt false "Whether or not to enable obs-studio";
  };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ obs-studio ]; };
}
