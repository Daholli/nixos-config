topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      nixpkgs = {
        config.allowUnfree = true;
      };

      # Enable binfmt emulation.
      # boot.binfmt.emulatedSystems = [
      #   "aarch64-linux"
      # ];

      environment.systemPackages = with pkgs; [
        teamviewer
        teams-for-linux

        obsidian
        diebahn

        termscp
        nixpkgs-review
      ];

      services.teamviewer.enable = true;
      environment.pathsToLink = [ "/libexec" ];

      programs.ssh.extraConfig = ''
        AddressFamily inet
      '';

      imports = with topLevel.config.flake.modules.nixos; [
        inputs.nixos-hardware.nixosModules.common-cpu-amd
        inputs.nixos-hardware.nixosModules.common-pc
        inputs.nixos-hardware.nixosModules.common-pc-ssd
        inputs.catppuccin.nixosModules.catppuccin

        # System modules
        base
        dev
        desktop
        games

        # hardware
        audio
        bluetooth
        amdgpu

        # desktops
        # hyprland
        niri

        # apps
        _1password

        # Users
        cholli
        root
      ];

      sops.secrets = {
        "remotebuild/private-key" = {
          sopsFile = ../../../secrets/secrets.yaml;
          owner = "cholli";
          mode = "0400";
        };

        "cholli/private-key" = {
          sopsFile = ../../../secrets/secrets.yaml;
          mode = "0600";
        };
      };

      fileSystems."/mnt/pi_share" = {
        device = "cholli@192.168.178.2:/storage/";
        fsType = "sshfs";

        options = [
          # Filesystem options
          "allow_other" # for non-root access
          "_netdev" # this is a network fs
          "x-systemd.automount" # mount on demand

          # SSH options
          "reconnect" # handle connection drops
          "ServerAliveInterval=15" # keep connections alive
          "IdentityFile=${config.sops.secrets."cholli/private-key".path}"
        ];
      };

      nix = {
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
        buildMachines = [
          {
            hostName = "nixberry";
            sshUser = "remotebuild";
            sshKey = config.sops.secrets."remotebuild/private-key".path;
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
    };
}
