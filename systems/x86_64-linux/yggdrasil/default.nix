{
  inputs,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    jetbrains.rust-rover
    inputs.pyfa
    teamspeak_client
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      vivaldi = enabled;
      discord = enabled;
      _1password = enabled;
      onedrive = enabled;
      factorio-server = enabled;
    };

    system = {
      autoUpgrade = {
        enable = true;
        time = "10:00";
      };
      hardware = {
        bluetooth = enabled;
        gpu.nvidia = enabled;
      };
    };

    security.gpg = enabled;
  };

  system.stateVersion = "23.11";
}
