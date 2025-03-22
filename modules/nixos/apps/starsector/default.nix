{
  config,
  lib,
  namespace,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.apps.starsector;
in
{
  options.${namespace}.apps.starsector = {
    enable = mkEnableOption "Whether or not to enable the game starsector.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      starsector
    ];
  };
}
