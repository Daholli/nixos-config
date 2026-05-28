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
        nix-serve

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
        name = "monolith";
        # default labels = [ "native:host" ]
        maxJobs = 1;
      };
    };
}
