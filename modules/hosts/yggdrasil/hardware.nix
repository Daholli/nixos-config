{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      boot = {
        zfs.package = pkgs.zfs_2_4;
        kernelPackages = pkgs.linuxPackages_latest;
        extraModulePackages = with config.boot.kernelPackages; [ r8125 ];
        blacklistedKernelModules = [ "r8169" ];

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

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;
    };
}
