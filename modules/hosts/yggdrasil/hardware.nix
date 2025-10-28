{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/yggdrasil" =
    { lib, pkgs, ... }:
    {

      boot = {
        kernelPackages = pkgs.linuxPackages_latest;

        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        initrd.availableKernelModules = [
          "nvme"
          "ahci"
          "xhci_pci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
        kernelModules = [ "kvm-amd" ];

      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/b1a956f4-91d5-456e-a92b-be505bb719bd";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-uuid/B4D4-8BA0";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        "/storage" = {
          device = "/dev/disk/by-uuid/c3c1dec1-7716-4c37-a3f2-bb60f9af84fd";
          fsType = "ext4";
        };

        "/var/lib/bluetooth" = {
          device = "/persist/var/lib/bluetooth";
          options = [
            "bind"
            "noauto"
            "x-systemd.automount"
          ];
          noCheck = true;
        };
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/4bec00ec-e9eb-4034-836a-ecf15e0bb40e"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;
    };
}
