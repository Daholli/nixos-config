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
            Enable = "Sink,Media,Socket";
            Disable = "Handsfree,Headset,Source";
          };
        };
      };
    };
}
