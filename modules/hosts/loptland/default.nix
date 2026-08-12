topLevel: {
  flake.modules.nixos."hosts/loptland" =
    {
      config,
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

      sops.secrets."modern-recorder/deploy-key" = {
        sopsFile = ../../../secrets/secrets-loptland.yaml;
        mode = "0440";
        owner = "root";
        group = "secrets-access";
      };

      programs.ssh = {
        extraConfig = ''
          Host git.christophhollizeck.dev
            IdentityFile ${config.sops.secrets."modern-recorder/deploy-key".path}
            IdentitiesOnly yes
        '';
        knownHosts."git.christophhollizeck.dev".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxMv6Fxv+4Kgf0Uv6qBPqz2DXHt0yE9BE86X3rgubGC";
      };

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
