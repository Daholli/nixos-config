{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.remotebuild;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.${namespace}.services.remotebuild = {
    enable = mkEnableOption "Enable remotebuild";
  };

  config = mkIf cfg.enable {
    users.users.remotebuild = {
      isNormalUser = true;
      createHome = false;
      group = "remotebuild";

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYZjG+XPNoVHVdCel5MK4mwvtoFCqDY1WMI1yoU71Rd root@yggdrasil"
      ];
    };

    users.groups.remotebuild = { };

    nix = {
      nrBuildUsers = 64;
      settings = {
        trusted-users = [ "remotebuild" ];

        min-free = 10 * 1024 * 1024;
        max-free = 200 * 1024 * 1024;

        max-jobs = "auto";
        cores = 0;
      };
    };

    systemd.services.nix-daemon.serviceConfig = {
      MemoryAccounting = true;
      MemoryMax = "90%";
      OOMScoreAdjust = 500;
    };
  };
}
