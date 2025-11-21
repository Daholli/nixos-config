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

      # hack
      environment.systemPackages = [ pkgs.dconf ];

      programs.nix-ld.enable = false;

      imports =
        with config.flake.modules.nixos;
        with inputs.nixos-raspberrypi.nixosModules;
        [
          inputs.catppuccin.nixosModules.catppuccin
          raspberry-pi-5.base

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

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
        fsType = "ext4";
      };

      fileSystems."/boot/firmware" = {
        device = "/dev/disk/by-uuid/2178-694E";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

    };
}
