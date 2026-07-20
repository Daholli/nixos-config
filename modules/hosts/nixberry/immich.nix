{
  flake.modules.nixos."hosts/nixberry" = _: {
    services.immich = {
      enable = true;
      mediaLocation = "/storage/immich";
      host = "0.0.0.0";
      openFirewall = true;
    };

    systemd.tmpfiles.rules = [
      "d /storage/immich 0750 immich immich -"
    ];
  };
}
