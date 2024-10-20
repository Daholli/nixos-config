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

  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-move-transition
      ];
    };

  };
}
