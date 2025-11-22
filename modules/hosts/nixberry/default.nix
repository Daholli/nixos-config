{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/nixberry" =
    {
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
      };

      # hack, homemanager needs it
      environment.systemPackages = [ pkgs.dconf ];

      # build failure
      programs.nix-ld.enable = false;

      imports =
        with config.flake.modules.nixos;
        with inputs.nixos-raspberrypi.nixosModules;
        [
          inputs.catppuccin.nixosModules.catppuccin
          raspberry-pi-5.base
          raspberry-pi-5.page-size-16k
          raspberry-pi-5.display-vc4

          # System modules
          base
          server

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
        useRoutingFeatures = "server";
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

      services.home-assistant = {
        enable = false;
        configWritable = true;
        extraComponents = [
          "default_config"
          "analytics"
          "shopping_list"
          "fritzbox"
          "met"
          "esphome"
          "rpi_power"
          "tuya"
        ];

        customComponents = with pkgs.home-assistant-custom-components; [
          smartthinq-sensors
          sleep_as_android
        ];

        extraPackages =
          python3Packages: with python3Packages; [
            ical
          ];

        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          mushroom
          bubble-card
          clock-weather-card
          vacuum-card
        ];

        config = {
          homeassistant = {
            latitude = 49.4;
            longitude = 8.6;
            temperature_unit = "C";
            unit_system = "metric";

            external_url = "https://ha.christophhollizeck.dev";
            internal_url = "http://192.168.178.2:8123";
          };

          default_config = "";

          mobile_app = "";
          recorder = "";

          lovelace = {
            # mode = "yaml";
            resources = [
              {
                url = "/local/nixos-lovelace-modules/vacuum-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/bubble-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/clock-weather-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/mushroom.js";
                type = "module";
              }
            ];
          };

          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [
              "100.86.250.97" # loptland tailscale
            ];
          };
        };
        openFirewall = true;
      };
    };
}
