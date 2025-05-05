{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.hydra;
  inherit (lib) mkIf mkOption mkEnableOption;
in
{
  options.${namespace}.services.hydra = {
    enable = mkEnableOption "Enable Hydra CI";
    httpPort = mkOption {
      type = lib.types.int;
      default = 2000;
      description = "The path to host the http server on, relevant for nginx forwarding";
    };

    enableCache = mkEnableOption "Enable cache using nix-server";
  };

  config = mkIf cfg.enable {
    services.nix-serve = mkIf cfg.enableCache {
      enable = true;
      secretKeyFile = "/var/cache-priv-key.pem";
    };

    services.hydra = {
      enable = true;
      hydraURL = "http://localhost:${toString cfg.httpPort}";
      port = cfg.httpPort;
      notificationSender = "hydra@localhost";
      useSubstitutes = true;
    };
  };
}
