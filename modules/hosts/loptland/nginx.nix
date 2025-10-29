{
  flake.modules.nixos."hosts/loptland" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domainName = "christophhollizeck.dev";
      forgejoPort = 3000;
      hydraPort = 2000;
    in
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;

        virtualHosts = {
          "git.${domainName}" = {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              extraConfig = ''
                client_max_body_size 200M;
              '';
              proxyPass = "http://localhost:${toString forgejoPort}/";
            };
          };

          "hydra.${domainName}" = lib.mkIf config.services.hydra.enable {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              proxyPass = "http://localhost:${toString hydraPort}/";
            };
          };

          "ha.${domainName}" = {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              # tailscale ip
              extraConfig = ''
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
              proxyPass = "http://100.86.23.74:8123";
            };
          };

          "nixcache.${domainName}" = lib.mkIf config.services.nix-serve.enable {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
            };
          };

          "_" = {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              proxyPass = "https://${domainName}";
            };
          };
        };
      };

    };
}
