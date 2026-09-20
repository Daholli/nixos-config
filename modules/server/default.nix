{
  flake.modules.nixos.server = _: {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://git.christophhollizeck.dev/Daholli/nixos-config";
      dates = "06:30";
      randomizedDelaySec = "30m";
      fixedRandomDelay = true;
      allowReboot = false;
    };

  };
}
