{
  flake.modules.nixos.server = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kitty.terminfo ];

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
