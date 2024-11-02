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
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [
        pkgs.nvidia-vaapi-driver
      ];
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable; # stable, beta
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    boot.kernelParams = [
      "nvidia_drm.fbdev=1"

      # TODO: remove after https://github.com/NVIDIA/open-gpu-kernel-modules/pull/692
      # and similar are merged and build in nixpkgs-unstable.
      # WARNING: this disables tty output and thus hides boot logs.
      "initcall_blacklist=simpledrm_platform_driver_init"
    ];
  };
}
