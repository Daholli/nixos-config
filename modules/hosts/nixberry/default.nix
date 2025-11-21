{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/nixberry" =
    { inputs, pkgs, ... }:
    let

      ipAddress = "192.168.178.2";
      sopsFile = ../../../secrets/secrets-nixberry.yaml;
      kernelBundle = pkgs.linuxAndFirmware.v6_6_31;
    in
    {
      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = {
          system = "aarch64-linux";
        };

        overlays = [
          (self: super: {
            inherit (kernelBundle) raspberrypiWirelessFirmware;
            inherit (kernelBundle) raspberrypifw;
          })
        ];
      };

      boot = {
        loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
        loader.raspberryPi.bootloader = "kernel";
        kernelPackages = kernelBundle.linuxPackages_rpi5;
      };

      system.nixos.tags =
        let
          cfg = config.boot.loader.raspberryPi;
        in
        [
          "raspberry-pi-${cfg.variant}"
          cfg.bootloader
          config.boot.kernelPackages.kernel.version
        ];

      imports =
        with config.flake.modules.nixos;
        with inputs.nixos-raspberrypi.nixosModules;
        [
          inputs.catppuccin.nixosModules.catppuccin
          raspberry-pi-5.base
          raspberry-pi-5.page-size-16k # Recommended: optimizations and fixes for issues arising from 16k memory page size (only for systems running default rpi5 (bcm2712) kernel)
          raspberry-pi-5.bluetooth
          raspberry-pi-5.display-vc4 # display

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

        wireless = {
          enable = true;
          networks = {
            "Slow Internet" = {
              pskRaw = "521b6d766b27276c29c7b6bec5b495b1c52bf88b0682277e65b37dc649b630de";
            };
          };
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
              "1.1.1.1"
              "1.0.0.1"
              "8.8.8.8"
              "8.8.4.4"
            ];
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
          };

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
        };
      };

      services.home-assistant = {
        enable = true;
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
