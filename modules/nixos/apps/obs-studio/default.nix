{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.obs-studio;
in
{
  options.wyrdgard.apps.obs-studio = with types; {
    enable = mkBoolOpt false "Whether or not to enable obs-studio";
  };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ obs-studio ]; };
}
