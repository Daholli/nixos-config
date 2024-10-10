{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.submodules.socials;
in
{
  options.${namespace}.submodules.socials = with types; {
    enable = mkBoolOpt false "Whether to enable social apps";
  };

  config = mkIf cfg.enable {
    ${namespace} = {
      apps = {
        discord = enabled;
        teamspeak = enabled;
      };
    };
  };
}
