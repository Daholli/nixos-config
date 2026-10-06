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
      # Steam Frame adapter needs WPA3 on 6 GHz, which only works with iwd here
      networking.networkmanager.wifi.backend = "iwd";
      # NM tears down the Frame link, so iwd owns the adapter (custom mode on the headset)
      networking.networkmanager.unmanaged = [ "mac:9c:04:b6:41:09:79" ];
      networking.wireless.iwd.settings.General.EnableNetworkConfiguration = true;
      # 6 GHz stays disabled under the default world regdomain
      hardware.wirelessRegulatoryDatabase = true;
      boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="DE"
      '';

      boot = {
        zfs = {
          package = pkgs.zfs;
          forceImportRoot = false;
        };
        kernelPackages = latestKernelPackage;
        extraModulePackages = with config.boot.kernelPackages; [ r8125 ];
        blacklistedKernelModules = [
          "r8169"
          # onboard MT7922 Wi-Fi races the Steam Frame adapter for the headset AP
          "mt7921e"
        ];

        kernelParams = [ "split_lock_detect=off" ];

        loader = {
          efi.canTouchEfiVariables = true;
          limine = {
            enable = true;
          };
        };

        initrd.availableKernelModules = [
          "nvme"
          "ahci"
          "xhci_pci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
        kernelModules = [
          "kvm-amd"
          "ntsync"
        ];

      };

      # imports = [
      #   inputs.nix-gaming-edge.nixosModules.mesa-git
      # ];

      # nixpkgs.overlays = [ inputs.nix-gaming-edge.overlays.mesa-git ];

      # drivers.mesa-git = {
      #   enable = true;
      #   cacheCleanup = {
      #     enable = true;
      #     protonPackage = pkgs.proton-ge-bin;
      #   };
      #   steamOrphanCleanup = {
      #     enable = true;
      #   };
      # };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;
    };
}
