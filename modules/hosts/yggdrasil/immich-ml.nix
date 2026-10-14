{ config, ... }:
let
  immichVersion = config.flake.nixosConfigurations.nixberry.config.services.immich.package.version;
in
{
  flake.modules.nixos."hosts/yggdrasil" = _: {
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;

      dockerCompat = true;
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:v${immichVersion}-rocm";
        ports = [ "3003:3003" ];
        volumes = [ "immich-model-cache:/cache" ];
        extraOptions = [
          "--device=/dev/kfd"
          "--device=/dev/dri"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 3003 ];
  };
}
