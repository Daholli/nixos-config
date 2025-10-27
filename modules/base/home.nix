{
  flake.modules = {
    nixos.base = {
      nixpkgs.config.allowUnFree = true;
      home-manager = {
        backupFileExtension = "bak";
        useUserPackages = true;
        useGlobalPkgs = true;
      };
    };

    homeManager.base = {
      programs.home-manager.enable = true;

      services = {
        home-manager.autoExpire = {
          enable = true;
          frequency = "weekly";
          store.cleanup = true;
        };
      };
    };
  };
}
