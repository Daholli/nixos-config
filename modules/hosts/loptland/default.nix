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

      # flake.nix's modern-recorder input is a private repo served by this
      # same box's own Forgejo, over git+ssh://forgejo@git.christophhollizeck.dev.
      # root's `system.autoUpgrade` (services/default.nix) fetches it
      # non-interactively, so it needs its own identity rather than relying on
      # an interactive ssh-agent. Read-only deploy key registered on
      # Daholli/Coda-Video-Recorder; rotate with
      # `sops secrets/secrets-loptland.yaml`. The known-hosts entry pins this
      # host's own ssh_host_ed25519_key, since git.christophhollizeck.dev
      # resolves back to loptland itself.
      sops.secrets."modern-recorder/deploy-key" = {
        sopsFile = ../../../secrets/secrets-loptland.yaml;
        mode = "0400";
        owner = "root";
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
