topLevel: {
  flake.modules.nixos."hosts/loptland" =
    {
      config,
      inputs,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    let
      domainName = "christophhollizeck.dev";
      sopsFile = ../../../secrets/secrets-loptland.yaml;
    in
    {
      nixpkgs.config.allowUnfree = true;
      services.qemuGuest.enable = true;

      # TODO: dunno why I need this packge
      environment.systemPackages = [ pkgs.dconf ];

      imports =
        with topLevel.config.flake.modules.nixos;
        [
          (modulesPath + "/profiles/qemu-guest.nix")
          inputs.catppuccin.nixosModules.catppuccin

          # System modules
          base
          server
          loptland-acme
          hydra
          forgejo
          forgejo-runner

          # game server
          minecraft-server
          factorio-server

          # apps

          # Users
          cholli
        ]
        ++ [
          {
            home-manager.users.cholli = {
              imports = with topLevel.config.flake.modules.homeManager; [
                inputs.catppuccin.homeModules.catppuccin

                # components
                base

                # Activate all user based config
                cholli
              ];
            };
          }

        ];

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      services.resolved = {
        enable = true;
        domains = [ "~." ];
      };

      networking.firewall.allowedTCPPorts = [
        3000
        80
        443
      ];

      sops.secrets = {
        "hydra/remotebuild/private-key" = {
          inherit sopsFile;
          owner = config.systemd.services.hydra-queue-runner.serviceConfig.User;
          mode = "0400";
        };
      };

      nix = {
        distributedBuilds = true;

        extraOptions = ''
          builders-use-substitutes = true
        '';

        buildMachines = [
          {
            hostName = "localhost";
            protocol = null;
            system = "x86_64-linux";

            supportedFeatures = [
              "kvm"
              "nixos-test"
              "big-parallel"
              "benchmark"
            ];
          }
          {
            hostName = "nixberry";
            sshUser = "remotebuild";
            sshKey = config.sops.secrets."hydra/remotebuild/private-key".path;
            systems = [ "aarch64-linux" ];
            protocol = "ssh";

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
