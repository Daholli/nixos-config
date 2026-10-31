{
  flake.modules.nixos.server = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.kitty.terminfo ];

    system.autoUpgrade = {
      enable = true;
      flake = "git+https://git.christophhollizeck.dev/Daholli/nixos-config";
      dates = "06:30";
      randomizedDelaySec = "30m";
      fixedRandomDelay = true;
      allowReboot = lib.mkDefault true;
      rebootWindow = {
        lower = "06:30";
        upper = "08:30";
      };
    };

  };
}
