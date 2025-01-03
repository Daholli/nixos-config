{
  config,
  inputs,
  lib,
  modulesPath,
  namespace,
  ...
}:

with lib.${namespace};
let
  inherit (lib) mkForce;

  ipAddress = "192.168.178.2";
in
{
  imports = with inputs.nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    raspberry-pi-5
  ];

  security.sudo.wheelNeedsPassword = false;
  users.users.remotebuild = {
    isNormalUser = true;
    createHome = false;
    group = "remotebuild";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYZjG+XPNoVHVdCel5MK4mwvtoFCqDY1WMI1yoU71Rd root@yggdrasil"
    ];
  };

  users.groups.remotebuild = { };

  nix = {
    nrBuildUsers = 64;
    settings = {
      trusted-users = [ "remotebuild" ];

      min-free = 10 * 1024 * 1024;
      max-free = 200 * 1024 * 1024;

      max-jobs = "auto";
      cores = 0;
    };
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryAccounting = true;
    MemoryMax = "90%";
    OOMScoreAdjust = 500;
  };

  networking = {
    interfaces.wlan0 = {
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
  };

  networking.firewall = {
    allowedTCPPorts = [
      53
      80
    ];
    allowedUDPPorts = [
      53
    ];
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

    };
  };

  # Pi specific stuff  
  raspberry-pi-nix.board = "bcm2712";
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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  ${namespace} = {
    submodules.basics = enabled;

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
