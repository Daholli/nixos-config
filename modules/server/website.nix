{
  flake.modules.nixos.website =
    { inputs, pkgs, ... }:
    let
      domainName = "christophhollizeck.dev";
    in
    {
      services.nginx.virtualHosts.${domainName} = {
        forceSSL = true;
        useACMEHost = domainName;
        root = "${inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default}";

        # Astro emits content-hashed assets here
        locations."/_astro/".extraConfig = ''
          add_header Cache-Control "public, max-age=31536000, immutable";
        '';
      };
    };
}
