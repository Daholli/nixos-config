{
  flake.modules.nixos.nix-serve = _: {
    services.nix-serve = {
      enable = true;
      secretKeyFile = "/var/cache-priv-key.pem";
    };
  };
}
