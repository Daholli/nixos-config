{
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    path-of-building
    teams-for-linux
    obsidian
    zed-editor
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  programs.ssh.extraConfig = ''
    AddressFamily inet
  '';

  ${namespace} = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      _1password = enabled;
      obs-studio = enabled;
      cli-apps.helix = enabled;
    };

    desktop.hyprland = {
      enable = true;
      settings = {
        monitor = [
          #Ultrawide
          "DP-2,3440x1440@144, 0x0, 1"
          #Vertical
          "HDMI-A-1, 1920x1080@144, auto-right, 1, transform, 1"
          # nividia kernel issues
          "Unknown-1, disable"
        ];

        cursor = {
          no_hardware_cursors = true;
        };

        exec-once = [
          "xrandr --output DP-2 --primary"
          "[workspace 1 silent] obsidian --disabled-gpu"
          "[workspace 9 silent] git-butler"
        ];

        workspace = [
          "1, monitor:DP-2"
          "2, monitor:DP-2"
          "3, monitor:DP-2"
          "4, monitor:DP-2"
          "5, monitor:DP-2"
          "6, monitor:DP-2"
          "7, monitor:HDMI-A-1"
          "8, monitor:HDMI-A-1"
          "9, monitor:HDMI-A-1"
        ];

        windowrulev2 = [
          "workspace 8 silent, class:^(steam)$, title:^(Friends List)"
          "workspace 8 silent, class:^(discord)$, title:^(Discord)"
          "workspace 7 silent, class:^(zen-alpha)$, title:^(da_holIi - Chat - Twitch)"
          "workspace 7 silent, class:^(com.obsproject.Studio)$"
        ];
      };
    };

    services = {
      factorio-server = disabled;
    };

    system = {
      hardware = {
        bluetooth = enabled;
        gpu.nvidia = enabled;
      };
    };

    security.gpg = enabled;
  };

  system.stateVersion = "23.11";
}
