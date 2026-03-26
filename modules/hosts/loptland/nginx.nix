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

          "matrix.alwayssleepy.online" = lib.mkIf config.services.matrix-synapse.enable {
            forceSSL = true;
            useACMEHost = "alwayssleepy.online";

            locations."/" = {
              proxyPass = "http://localhost:${toString 8008}";
              extraConfig = ''
                client_max_body_size 50M;
              '';
            };
          };

          # .well-known Matrix delegation so Matrix IDs are @user:alwayssleepy.online
          "alwayssleepy.online" = {
            forceSSL = true;
            useACMEHost = "alwayssleepy.online";

            locations."/.well-known/matrix/server" = {
              extraConfig = ''
                default_type application/json;
                return 200 '{"m.server":"matrix.alwayssleepy.online:443"}';
              '';
            };

            locations."/.well-known/matrix/client" = {
              extraConfig = ''
                default_type application/json;
                add_header 'Access-Control-Allow-Origin' '*';
                return 200 '{"m.homeserver":{"base_url":"https://matrix.alwayssleepy.online"}}';
              '';
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
