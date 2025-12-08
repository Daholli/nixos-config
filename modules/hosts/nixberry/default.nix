topLevel: {
  flake.modules.nixos."hosts/nixberry" =
    {
      config,
      inputs,
      lib,
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
        crossSystem = lib.mkIf (pkgs.stdenv.buildPlatform.system != "aarch64-linux") (
          lib.systems.elaborate "aarch64-linux"
        );
        overlays = [
          (final: prev: {
            homeassistant =
              inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.homeassistant;
          })
        ];
      };

      boot.loader.raspberryPi.bootloader = "kernel";

      # hack, homemanager needs it
      programs.dconf.enable = true;

      sops.secrets.tailscale_key = {
        inherit sopsFile;
      };

      imports =
        with topLevel.config.flake.modules.nixos;
        with inputs.nixos-raspberrypi.nixosModules;
        [
          inputs.catppuccin.nixosModules.catppuccin
          raspberry-pi-5.base
          raspberry-pi-5.page-size-16k
          raspberry-pi-5.display-vc4

          # System modules
          base
          server
          bluetooth

          cholli
          root
        ];

      services.tailscale = {
        enable = true;
        package = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
        useRoutingFeatures = "server";
        authKeyFile = config.sops.secrets.tailscale_key.path;
        extraUpFlags = [ "--advertise-exit-node" ];
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
        interfaces.wlan0 = {
          ipv4.addresses = [
            {
              address = "192.168.178.3";
              prefixLength = 24;
            }
          ];
          useDHCP = true;
        };
        defaultGateway = {
          address = "192.168.178.1";
          interface = "wlan0";
        };

        firewall = {
          allowedTCPPorts = [
            443
            53
            80

            # Sonos
            1400
            1443
          ];
          allowedUDPPorts = [
            53
          ];
        };
      };

      services.adguardhome = {
        enable = true;
        host = ipAddress;
        port = 80;

        settings = {
          http = {
            address = "0.0.0.0:80";
          };
          dns = {
            ratelimit = 0;
            bind_hosts = [ "0.0.0.0" ];
            upstream_dns = [
              "tls://unfiltered.adguard-dns.com"
              "https://unfiltered.adguard-dns.com/dns-query"
              "tls://dns.quad9.net"
              "https://dns.quad9.net/dns-query"
              "tls://security.cloudflare-dns.com"
              "https://security.cloudflare-dns.com/dns-query"
            ];
            upstream_mode = "parallel";
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
            rewrites = [
              {
                domain = "nixberry.fritz.box";
                answer = "192.168.178.2";
                enabled = true;
              }
              {
                domain = "nixberry";
                answer = "192.168.178.2";
                enabled = true;
              }
            ];
          };

          user_rules = [
            "||qognify.sysaidit.com^$important"
            "||*.live.darktracesensor.com^$important"
          ];

          filters =
            map
              (url: {
                enabled = true;
                url = url;
              })
              [
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt" # AdGuard Dns filter
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt" # AdGuard Dns PopupHosts filter
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt" # Phishing
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt"
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt"
              ];

          statistics = {
            enabled = true;
            interval = "8760h";
          };
          clients = {
            persistent = [
              {
                name = "yggdrasil";
                ids = [ "192.168.178.51" ];
                tags = [
                  "device_pc"
                  "os_linux"
                ];
                uid = "019aac26-684c-7c2c-a43d-2253f4407d45";
                use_global_settings = true;
              }
              {
                name = "holli - phone";
                ids = [
                  "192.168.178.52"
                  "100.124.47.76"
                  "fd7a:115c:a1e0::b701:2f4f"
                ];
                tags = [
                  "device_phone"
                  "os_android"
                ];
                uid = "019aeb6c-62bf-7a55-a549-45e17b14ef64";
                use_global_settings = true;
              }
              {
                name = "nixberry";
                ids = [
                  "192.168.178.2"
                  "100.90.93.35"
                  "fd7a:115c:a1e0::dd01:5d34"
                ];
                tags = [
                  "device_pc"
                  "os_linux"
                ];
                uid = "019aac5a-760e-73f9-a246-3470dae6219d";
                use_global_settings = true;
              }
              {
                name = "work-laptop";
                ids = [ "192.168.178.48" ];
                tags = [
                  "device_pc"
                  "os_windows"
                ];
                uid = "019aac55-ae29-7c5e-aac0-baadd7157f92";
                use_global_settings = true;
              }
            ];
          };

        };
      };
    };
}
