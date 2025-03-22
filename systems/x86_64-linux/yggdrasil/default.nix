{
  inputs,
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

    # eve
    bottles
    pyfa

    unzip
  ];

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  programs.ssh.extraConfig = ''
    AddressFamily inet
  '';
  home-manager = {
    backupFileExtension = ".bak";
  };

  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "nixberry";
        sshUser = "remotebuild";
        sshKey = "/root/.ssh/remotebuild";
        systems = [ "aarch64-linux" ];
        protocol = "ssh-ng";

        supportedFeatures = [
          "nixos-test"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };

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
          "[workspace 1 silent] obsidian --disabled-gpu"
          "[workspace 9 silent] git-butler"

          "${pkgs.xorg.xrandr}/bin/xrandr --output DP-2 --primary"
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
          "workspace 8 silent, class:^(vesktop)$, title:^(Discord)"
          "workspace 7 silent, class:^(com.obsproject.Studio)$"
        ];
      };
    };

    services = {
      factorio-server = disabled;
    };

    tools.devenv = enabled;

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
