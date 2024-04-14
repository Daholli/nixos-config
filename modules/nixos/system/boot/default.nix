{
  options,
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
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    services.fstrim = enabled;
  };
}
