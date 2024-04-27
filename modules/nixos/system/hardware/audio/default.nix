{
  options,
  config,
  lib,
  pkgs,
  ...
}:
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
    environment.systemPackages = with pkgs; [
      noisetorch
      pavucontrol
    ];

    programs.noisetorch.enable = true;

    sound.enable = true;
    hardware.pulseaudio = disabled;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
          wireplumber.settings = {	
            bluetooth.autoswitch-to-headset-profile = false	
          }
        '')
        (pkgs.writeTextDir "share/wireplumber/policy.lua.d/11-bluetooth-policy.conf" ''
          bluetooth_policy.policy["media-role.use-headset-profile"] = false
        '')
      ];
    };
  };
}
