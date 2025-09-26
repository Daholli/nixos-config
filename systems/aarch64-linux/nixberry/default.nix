{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:

with lib.${namespace};
let
  inherit (lib) mkForce;

  ipAddress = "192.168.178.2";
  sopsFile = lib.snowfall.fs.get-file "secrets/secrets-nixberry.yaml";

in
{
  nixpkgs.hostPlatform = {
    system = "aarch64-linux";
  };

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

  systemd.tmpfiles.rules = [
    # "C+ /var/lib/hass/custom_components/tuya_vacuum_maps - - - - ${inputs.tuya-vaccum-maps}/custom_components/tuya_vacuum_maps"
    # "Z /var/lib/hass/custom_components 770 hass hass - -"
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
  ];

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

  # Pi specific stuff
  raspberry-pi-nix = {
    board = "bcm2712";
    # kernel-build-system = "x86_64-linux";
  };

  hardware = {
    raspberry-pi = {
      config = {
        all = {
          base-dt-params = {
            BOOT_UART = {
              value = 1;
              enable = true;
            };
            uart_2ndstage = {
              value = 1;
              enable = true;
            };
          };
          dt-overlays = {
            disable-bt = {
              enable = true;
              params = { };
            };
          };
        };
      };
    };
  };

  ${namespace} = {
    submodules.basics = enabled;

    services = {
      openssh = enabled;
      remotebuild = enabled;
    };

    apps.cli-apps.helix.pkg = pkgs.helix;

    system = {
      # cachemiss for webkit gtk
      hardware.networking.enable = mkForce false;

      # rasberry pi uses alternative boot settings
      boot.enable = mkForce false;
    };

    user.trustedPublicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
