{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.hardware.gpu.nvidia;
in
{
  options.${namespace}.system.hardware.gpu.nvidia = {
    enable = mkEnableOption "Enable Nvidia GPU";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nvidia-vaapi-driver ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable; # stable, beta
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
