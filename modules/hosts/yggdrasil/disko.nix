{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      ...
    }:
    {
      imports = [ inputs.disko.nixosModules.disko ];

      boot.supportedFilesystems = [ "zfs" ];
      networking.hostId = "007f0200";

      services.zfs = {
        autoScrub.enable = true;
        autoSnapshot.enable = true;
        trim.enable = true;
      };

      disko.devices = {
        disk = {
          x = {
            type = "disk";
            device = "/dev/nvme0n1";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "2G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zroot";
                  };
                };
              };
            };
          };
          y = {
            type = "disk";
            device = "/dev/nvme1n1";
            content = {
              type = "gpt";
              partitions = {
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zroot";
                  };
                };
              };
            };
          };
        };

        zpool = {
          zroot = {
            type = "zpool";
            mode = "mirror";

            options = {
              ashift = "12";
              autotrim = "on";
            };

            rootFsOptions = {
              canmount = "off";
              checksum = "edonr";
              compression = "zstd";
              dnodesize = "auto";
              mountpoint = "none";
              normalization = "formD";
              relatime = "on";
              "com.sun:auto-snapshot" = "false";
            };

            datasets = {
              "local" = {
                type = "zfs_fs";
                options.mountpoint = "none";
              };
              "local/home" = {
                type = "zfs_fs";
                mountpoint = "/home";
                options = {
                  "com.sun:auto-snapshot" = "true";
                };
              };
              "local/steam" = {
                type = "zfs_fs";
                mountpoint = "/steam";
                options = {
                  "com.sun:auto-snapshot" = "false";
                  recordsize = "1M";
                  compression = "lz4";
                  casesensitivity = "insensitive";
                };
                postCreateHook = "chown cholli:users /steam";
              };
              "local/nix" = {
                type = "zfs_fs";
                mountpoint = "/nix";
                options."com.sun:auto-snapshot" = "false";
              };
              "local/persist" = {
                type = "zfs_fs";
                mountpoint = "/persist";
                options."com.sun:auto-snapshot" = "true";
              };
              "local/root" = {
                type = "zfs_fs";
                mountpoint = "/";
                options."com.sun:auto-snapshot" = "false";
                postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/local/root@blank$' || zfs snapshot zroot/local/root@blank";
              };
            };
          };
        };

      };
    };

}
