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
  cfg = config.${namespace}.system.hardware.audio;
in
{
  options.${namespace}.system.hardware.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pavucontrol
      easyeffects
    ];

    services.pulseaudio = disabled;
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
