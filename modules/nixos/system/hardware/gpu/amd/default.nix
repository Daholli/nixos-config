{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.system.hardware.gpu.amd;
in
{
  options.${namespace}.system.hardware.gpu.amd = {
    enable = mkEnableOption "Enable AMD GPU";
  };

  config = mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment = {
      variables = {
        AMD_VULKAN_ICD = "RADV";
      };
    };
  };
}
