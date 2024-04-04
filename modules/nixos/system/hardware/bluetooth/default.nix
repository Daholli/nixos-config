{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.system.hardware.bluetooth;
in
{
  options.wyrdgard.system.hardware.bluetooth = with types; {
    enable = mkBoolOpt false "Whether or not to enable bluetooth";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ libsForQt5.bluez-qt ];

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          KernelExperimental = true;
        };
      };
    };

    fileSystems."/var/lib/bluetooth" = {
      device = "/persist/var/lib/bluetooth";
      options = [
        "bind"
        "noauto"
        "x-systemd.automount"
      ];
      noCheck = true;
    };

    # https://github.com/NixOS/nixpkgs/issues/170573
  };
}
