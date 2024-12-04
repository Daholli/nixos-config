{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.tools.devenv;
in
{
  options.${namespace}.tools.devenv = {
    enable = mkEnableOption "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.devenv
    ];
  };
}
