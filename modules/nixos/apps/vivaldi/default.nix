{ options, config, lib, pkgs, ... }:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.vivaldi;
in
{
  options.wyrdgard.apps.vivaldi = with types; {
    enable = mkBoolOpt false "Whether or not to enable vivaldi browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vivaldi
      vivaldi-ffmpeg-codecs
    ];
  };
}
