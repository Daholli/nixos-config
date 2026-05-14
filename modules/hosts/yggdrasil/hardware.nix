{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      pkgs-master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      # Temporary: pinned mesa 26.0.6 while mesa-git is crashing. Remove once stable.
      pkgs-mesa-pinned = inputs.nixpkgs-mesa-26_0_6.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      zfsCompatibleKernelPackages = lib.filterAttrs (
        name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name) != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
      ) pkgs-master.linuxKernel.packages;
      # ) pkgs.linuxKernel.packages; # use this when reverting zfs back to nixos-unstable
      latestKernelPackage = lib.last (
        lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
          builtins.attrValues zfsCompatibleKernelPackages
        )
      );
    in
    {

      boot = {
        zfs = {
          package = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zfs;
          # package = pkgs.zfs; # nixos-unstable
          forceImportRoot = false;
        };
        kernelPackages = latestKernelPackage;
        extraModulePackages = with config.boot.kernelPackages; [ r8125 ];
        blacklistedKernelModules = [ "r8169" ];

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

      imports = [
        # inputs.nix-gaming-edge.nixosModules.mesa-git  # re-enable when mesa-git is stable
      ];

      # Temporarily pin mesa to 26.0.6 while mesa-git is crashing.
      # To re-enable mesa-git: restore the import above, restore the overlay and
      # drivers.mesa-git block below, and remove this hardware.graphics override.
      hardware.graphics = {
        package = pkgs-mesa-pinned.mesa;
        package32 = pkgs-mesa-pinned.pkgsi686Linux.mesa;
      };

      # nixpkgs.overlays = [ inputs.nix-gaming-edge.overlays.mesa-git ];  # re-enable with mesa-git

      # drivers.mesa-git = {  # re-enable when mesa-git is stable
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
