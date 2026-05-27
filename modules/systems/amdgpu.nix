{
  flake.modules.nixos.amdgpu = _: {
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
