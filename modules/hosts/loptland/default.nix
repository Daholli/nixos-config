{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/loptland" =
    {
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
        with config.flake.modules.nixos;
        [
          (modulesPath + "/profiles/qemu-guest.nix")
          inputs.catppuccin.nixosModules.catppuccin

          # System modules
          base
          server
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
              imports = with config.flake.modules.homeManager; [
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

      networking.firewall.allowedTCPPorts = [
        3000
        80
        443
      ];

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
            hostName = "100.86.23.74";
            sshUser = "remotebuild";
            sshKey = "/root/.ssh/remotebuild";
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
