{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.system.boot;
in
{
  options.wyrdgard.system.boot = with types; {
    enable = mkBoolOpt false "Whether or not to enable booting.";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    services.fstrim = enabled;
  };
}
