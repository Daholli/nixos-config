topLevel: {
  flake.modules.nixos."hosts/loptland" =
    {
      pkgs,
      modulesPath,
      ...
    }:
    {
      nixpkgs.config.allowUnfree = true;
      services.qemuGuest.enable = true;

      # TODO: dunno why I need this packge
      environment.systemPackages = [ pkgs.dconf ];

      imports = with topLevel.config.flake.modules.nixos; [
        (modulesPath + "/profiles/qemu-guest.nix")

        # System modules
        base
        server
        loptland-acme
        forgejo
        forgejo-runner

        # services
        matrix-synapse
        mautrix-discord
        mautrix-signal
        element-call
        element-web

        # game server
        # minecraft-server
        factorio-server

        # apps

        # Users
        cholli
        root
      ];

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      services.resolved = {
        enable = true;

        settings.Resolve.Domains = [ "~." ];
      };

      networking.firewall.allowedTCPPorts = [
        3000
        80
        443
      ];

      local.forgejoRunner = {
        sopsFile = ../../../secrets/secrets-loptland.yaml;
        name = "Loptland";
        uuid = "dace2c49-4ed9-4d8f-9afa-7e75afa0fe01";
        maxJobs = 1;

        container = {
          sopsFile = ../../../secrets/secrets-loptland.yaml;
          name = "Loptland container";
          uuid = "389bf7c2-6081-4d95-8f0a-7e0469d9d753";
          labels = [ "container:docker://node:20-bookworm" ];
        };
      };
    };
}
