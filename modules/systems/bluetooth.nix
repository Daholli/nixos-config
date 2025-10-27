{
  flake.modules.nixos.bluetooth =
    { ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
            KernelExperimental = true;
            Enable = "Source,Sink,Media,Socket";
          };
        };
      };

    };
}
