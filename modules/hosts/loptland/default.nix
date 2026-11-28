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
        prometheus-exporters
        unbound-resolver
        loptland-acme
        forgejo
        forgejo-runner
        circus

        # services
        attic
        matrix-synapse
        matrix-authentication-service
        mautrix-signal
        matrix-rtc
        sable-web
        website

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
        extraSetFlags = [ "--accept-dns=false" ];
      };

      networking = {
        firewall.allowedTCPPorts = [
          80
          443
        ];
        # SMTPS for the nixberry CI runner's audit mails.
        firewall.interfaces.tailscale0.allowedTCPPorts = [ 465 ];

        interfaces.ens3.ipv6.addresses = [
          {
            address = "2a03:4000:15:115:b849:e2ff:fe9a:60d1";
            prefixLength = 64;
          }
        ];
        defaultGateway6 = {
          address = "fe80::1";
          interface = "ens3";
        };
        dhcpcd.extraConfig = "noipv4ll";
      };

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

      local.attic.watchStore.enable = true;

      local.circus = {
        sopsFile = ../../../secrets/secrets-loptland.yaml;
        domain = "ci.christophhollizeck.dev";
        allowedUris = [
          "https://git.sable.moe/SableClient/sable-next"
          "https://git.christophhollizeck.dev/cholli/website.git"
        ];
        joinTokens.nixberry = "2731b449d3bba05def4f5400c2022b44f7f465681fe9369b4600f3fe4bf0ffa7";
        projects.nixos-config = {
          repo = "Daholli/nixos-config";
          branch = "develop";
          buildBranches = true;
          jobsets = [
            "nixosConfigurations"
            "packages"
            "devShells"
            "checks"
          ];
        };
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
