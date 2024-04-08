{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [ ];

  environment.pathsToLink = [ "/libexec" ];

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      vivaldi = enabled;
      discord = enabled;
      _1password = enabled;
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
  };

  system.stateVersion = "23.11";
}
