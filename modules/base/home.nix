{
  flake.modules.homeManager.base = {
    programs.home-manager.enable = true;

    services = {
      home-manager.autoExpire = {
        enable = true;
        frequency = "weekly";
        store.cleanup = true;
      };
    };
  };
}
