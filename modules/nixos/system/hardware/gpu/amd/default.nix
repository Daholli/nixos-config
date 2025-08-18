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

  amdvlk-run = pkgs.writeShellScriptBin "amdvlk-run" ''
    export VK_DRIVER_FILES="${pkgs.amdvlk}/share/vulkan/icd.d/amd_icd64.json:${pkgs.pkgsi686Linux.amdvlk}/share/vulkan/icd.d/amd_icd32.json"
    exec "$@"
  '';
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
      systemPackages = [ amdvlk-run ];
      variables = {
        AMD_VULKAN_ICD = "RADV";
      };
    };
  };
}
