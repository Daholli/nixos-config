{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      zfsCompatibleKernelPackages = lib.filterAttrs (
        name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name) != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
      ) pkgs.linuxKernel.packages;
      latestKernelPackage = lib.last (
        lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
          builtins.attrValues zfsCompatibleKernelPackages
        )
      );
    in
    {

      boot = {
        zfs.package = pkgs.zfs_2_4;
        kernelPackages = latestKernelPackage;
        extraModulePackages = with config.boot.kernelPackages; [ r8125 ];
        blacklistedKernelModules = [ "r8169" ];

        kernelParams = [ "split_lock_detect=off" ];

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
