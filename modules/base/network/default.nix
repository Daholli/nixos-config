{
  flake.modules.nixos.base =
    { hostConfig, ... }:
    {
      networking = {
        hostName = hostConfig.name;

        networkmanager = {
          enable = true;
        };
      };
    };
}
