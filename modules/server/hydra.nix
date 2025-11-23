{
  flake.modules.nixos.hydra =
    { ... }:
    let
      httpPort = 2000;
    in
    {
      services.nix-serve = {
        enable = true;
        secretKeyFile = "/var/cache-priv-key.pem";
      };

      services.hydra = {
        enable = true;
        hydraURL = "http://localhost:${toString httpPort}";
        port = httpPort;
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
      };

    };
}
