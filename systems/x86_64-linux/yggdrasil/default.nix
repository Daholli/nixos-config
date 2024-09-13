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
    pkgs.most
    pkgs.man-pages
    pkgs.man-pages-posix
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  services.xserver.displayManager.setupCommands = "xrandr --output HDMI-A-1 --off";

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      _1password = enabled;
      obs-studio = enabled;
    };

    desktop.hyprland = {
      enable = true;
      settings = {
        monitor = [
          #Ultrawide
          "DP-2,3440x1440@144, 0x0, 1"
          #Vertical
          "HDMI-A-1,1920x1080@144, auto-right, 1, transform, 1"
        ];

        exec-once = [
          "xrandr --output DP-2 --primary --output HDMI-A-1 --on"
          "hyprctl dispatch moveworkspacetomonitor 4 HDMI-A-1"
        ];

        workspace = [
          "1, monitor:DP-2, persistant:true"
          "2, monitor:HDMI-A-1, persistant:true"
          "3, monitor:DP-2, persistant:true, defaultName:3 Steam"
          "4, monitor:HDMI-A-1: persistant:true, defaultName:4 1Password"
          "5, monitor:DP-2, persistant:true"
        ];

        windowrulev2 = [
          "workspace 2, class:^(steam)$, title:^(Friends List)"
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
