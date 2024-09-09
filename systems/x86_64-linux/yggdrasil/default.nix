{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.wyrdgard) enabled;
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    path-of-building
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      _1password = enabled;
      obs-studio = enabled;
    };

    graphical-interface.desktop-manager.hyprland = {
      enable = true;
      settings = {
        monitor = [
          #Ultrawide
          "DP-2,3440x1440@144, 0x0, 1"
          #Vertical
          "HDMI-A-1,1920x1080@144, auto-right, 1, transform, 1"
        ];
        workspace = [
          "1, monitor:DP-2"
          "2, monitor:HDMI-A-1"
          "3, monitor:DP-2 on-created-empty:zen"
        ];
      };
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
