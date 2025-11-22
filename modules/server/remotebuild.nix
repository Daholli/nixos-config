{
  flake.modules.nixos.server =
    { lib, ... }:
    {
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

        daemonIOSchedClass = lib.mkDefault "idle";
        daemonCPUSchedPolicy = lib.mkDefault "idle";
      };

      systemd.services.nix-daemon.serviceConfig = {
        MemoryAccounting = true;
        MemoryMax = "90%";
        OOMScoreAdjust = 500;
        Slice = "-.slice";
      };

    };
}
