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
      matrixDomain = "alwayssleepy.online";
      livekitPort = 7880;
      lkJwtPort = 8089;
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

          "matrix.${matrixDomain}" = lib.mkIf config.services.matrix-synapse.enable {
            forceSSL = true;
            useACMEHost = matrixDomain;

            locations."/" = {
              proxyPass = "http://localhost:${toString 8008}";
              extraConfig = ''
                client_max_body_size 50M;
              '';
            };
          };

          "call.${matrixDomain}" = lib.mkIf config.services.lk-jwt-service.enable {
            forceSSL = true;
            useACMEHost = matrixDomain;

            locations."= /config.json" = {
              extraConfig = ''
                default_type application/json;
                return 200 '${builtins.toJSON {
                  default_server_config = {
                    "m.homeserver" = {
                      base_url = "https://matrix.${matrixDomain}";
                      server_name = matrixDomain;
                    };
                  };
                  livekit = {
                    livekit_service_url = "https://call.${matrixDomain}/livekit/jwt";
                  };
                }}';
              '';
            };

            locations."/" = {
              root = "${pkgs.element-call}";
              tryFiles = "$uri /index.html";
              extraConfig = ''
                add_header Cache-Control "no-cache" always;
              '';
            };

            # Proxy lk-jwt-service for token generation
            locations."/livekit/jwt" = {
              proxyPass = "http://localhost:${toString lkJwtPort}";
            };

            # Proxy LiveKit SFU websocket
            locations."/livekit/sfu" = {
              proxyPass = "http://localhost:${toString livekitPort}";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
              '';
            };
          };

          # .well-known Matrix delegation so Matrix IDs are @user:alwayssleepy.online
          "alwayssleepy.online" = {
            forceSSL = true;
            useACMEHost = matrixDomain;

            locations."/.well-known/matrix/server" = {
              extraConfig = ''
                default_type application/json;
                return 200 '{"m.server":"matrix.${matrixDomain}:443"}';
              '';
            };

            locations."/.well-known/matrix/client" = {
              extraConfig = ''
                default_type application/json;
                add_header 'Access-Control-Allow-Origin' '*';
                return 200 '{"m.homeserver":{"base_url":"https://matrix.${matrixDomain}"},"org.matrix.msc4143.rtc_foci":[{"type":"livekit","livekit_service_url":"https://call.${matrixDomain}/livekit/jwt"}]}';
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
