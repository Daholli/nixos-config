{
  flake.modules.nixos.base =
    { config, lib, ... }:
    {
      # a hung ZFS pool freezes userspace silently; let the hardware watchdog reboot the box
      systemd.settings.Manager = lib.mkIf (config.boot.supportedFilesystems.zfs or false) {
        RuntimeWatchdogSec = "30s";
        RebootWatchdogSec = "5min";
      };
    };
}
