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
  imports = [
    ./hardware.nix
    ./hyprland_config.nix
  ];

  environment.systemPackages = with pkgs; [
    path-of-building
    teams-for-linux
    obsidian
    zed-editor

    # eve
    bottles
    pyfa

    # misc
    diebahn

    nixpkgs-review
    teamviewer
  ];

  services.teamviewer.enable = true;

  environment.pathsToLink = [ "/libexec" ];

  virtualisation.waydroid = enabled;

  programs.ssh.extraConfig = ''
    AddressFamily inet
  '';
  home-manager = {
    backupFileExtension = "bak";
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
      starsector = enabled;
    };

    desktop.hyprland = {
      enable = true;
    };

    services = {
      factorio-server = disabled;
    };

    tools.devenv = enabled;

    system = {
      hardware = {
        bluetooth = enabled;
        gpu.amd = enabled;
      };
    };

    security.gpg = enabled;
  };

  system.stateVersion = "23.11";
}
