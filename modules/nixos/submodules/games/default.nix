{
  config,
  lib,
  namespace,
  options,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.submodules.games;
in
{
  options.${namespace}.submodules.games = with types; {
    enable = mkBoolOpt false "Whether or not you want to enable steam and other games";
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [ prismlauncher ];

    ${namespace} = {
      apps = {
        steam = enabled;
      };
    };
  };
}
