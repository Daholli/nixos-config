{
  flake.modules.nixos.attic =
    { config, ... }:
    {
      sops = {
        secrets."attic/rs256-secret".sopsFile = ../../secrets/secrets-loptland.yaml;

        templates."attic.env".content = ''
          ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=${config.sops.placeholder."attic/rs256-secret"}
        '';
      };

      services.atticd = {
        enable = true;
        environmentFile = config.sops.templates."attic.env".path;

        settings = {
          listen = "127.0.0.1:8181";
          api-endpoint = "https://attic.christophhollizeck.dev/";
        };
      };
    };
}
