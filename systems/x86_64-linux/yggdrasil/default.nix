{
  pkgs,
  lib,
  ...
}:
with lib.wyrdgard;
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    jetbrains.rust-rover
    teamspeak_client
    path-of-building
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      vivaldi = enabled;
      zen-browser = enabled;
      discord = enabled;
      _1password = enabled;
      obs-studio = enabled;
    };

    services = {
      factorio-server = enabled;
      onedrive = enabled;
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
