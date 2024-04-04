{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.system.hardware.gpu.nvidia;
in
{
  options.wyrdgard.system.hardware.gpu.nvidia = with types; {
    enable = mkEnableOption "Enable Nvidia GPU";
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.beta; # stable, beta
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    services.xserver.displayManager.sddm.wayland.enable = lib.mkForce false;
  };
}
