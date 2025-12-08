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
    in
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;

        virtualHosts = {
          "git.${domainName}" = lib.mkIf config.services.forgejo.enable {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              extraConfig = ''
                client_max_body_size 200M;
              '';
              proxyPass = "http://localhost:${toString 3000}/";
            };
          };

          "hydra.${domainName}" = lib.mkIf config.services.hydra.enable {
            forceSSL = true;
            useACMEHost = domainName;

            locations."/" = {
              proxyPass = "http://localhost:${toString config.services.hydra.port}/";
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
              proxyPass = "http://nixberry:8123";
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
