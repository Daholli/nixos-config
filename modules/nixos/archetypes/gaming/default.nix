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
  cfg = config.${namespace}.archetypes.gaming;
in
{
  options.${namespace}.archetypes.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gaming archetype.";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      submodules = {
        basics = enabled;
        games = enabled;
        socials = enabled;
      };

      system.hardware = {
        audio = enabled;
      };

      apps = {
        zen-browser = enabled;
      };
    };
  };
}
