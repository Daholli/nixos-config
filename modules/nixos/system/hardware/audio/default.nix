{ options, config, lib, pkgs, ... }:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.system.hardware.audio;
in
{
  options.wyrdgard.system.hardware.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio";
  };

  config = mkIf cfg.enable {

    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32bit = true;
      pulse.enable = true;
    };
  };
}
