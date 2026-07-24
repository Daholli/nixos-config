{
  flake.modules.nixos.amdgpu = { pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = [
        pkgs.rocmPackages.clr.icd
      ];
    };

    environment = {
      variables = {
        AMD_VULKAN_ICD = "RADV";
      };
    };
  };
}
