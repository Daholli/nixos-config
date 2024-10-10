{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.apps.cli-apps.home-manager;
in
{
  options.${namespace}.apps.cli-apps.home-manager = {
    enable = mkBoolOpt true "Enable home-manager";
  };

  config = mkIf cfg.enable { programs.home-manager = enabled; };
}
