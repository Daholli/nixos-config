{
  flake.modules.nixos.server = _: {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://git.christophhollizeck.dev/Daholli/nixos-config";
      dates = "weekly";
      randomizedDelaySec = "6h";
      allowReboot = false;
    };

  };
}
