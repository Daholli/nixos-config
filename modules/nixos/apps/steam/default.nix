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
  cfg = config.${namespace}.apps.steam;
in
{
  options.${namespace}.apps.steam = {
    enable = mkEnableOption "Whether or not to enable support for Steam.";
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };

    environment.systemPackages = with pkgs; [
      protontricks
    ];
  };
}
