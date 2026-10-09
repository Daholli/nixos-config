topLevel: {
  flake.modules.nixos."hosts/nixberry" =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      ipAddress = "192.168.178.2";
      sopsFile = ../../../secrets/secrets-nixberry.yaml;
    in
    {
      nixpkgs = {
        config.allowUnfree = true;
      };

      boot.loader.raspberry-pi.bootloader = "kernel";

      zramSwap.enable = true;

      # hack, homemanager needs it
      programs.dconf.enable = true;

      sops.secrets.tailscale_key = {
        inherit sopsFile;
      };

      local.forgejoRunner = {
        sopsFile = ../../../secrets/secrets-nixberry.yaml;
        name = "nixberry";
        uuid = "ff308046-bd13-47e6-82c5-953d8cee9e41";
        maxJobs = 1;
      };

      imports =
        with topLevel.config.flake.modules.nixos;
        with inputs.nixos-raspberrypi.nixosModules;
        [
          raspberry-pi-5.base
          raspberry-pi-5.display-vc4

          # System modules
          base
          server
          prometheus-exporters
          unbound-resolver
          bluetooth
          forgejo-runner

          cholli
          root
        ];

      services.tailscale = {
        enable = true;
        package = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
        useRoutingFeatures = "server";
        authKeyFile = config.sops.secrets.tailscale_key.path;
        extraUpFlags = [ "--advertise-exit-node" ];
        extraSetFlags = [ "--accept-dns=false" ];
      };

      networking = {
        interfaces.end0 = {
          ipv4.addresses = [
            {
              address = ipAddress;
              prefixLength = 24;
            }
          ];
          useDHCP = true;
        };
        defaultGateway = {
          address = "192.168.178.1";
          interface = "end0";
        };

        firewall.allowedTCPPorts = [
          # Sonos
          1400
          1443
        ];
      };
    };
}
