{
  flake.modules.nixos.website =
    { inputs, pkgs, ... }:
    let
      domainName = "christophhollizeck.dev";
    in
    {
      # Exposed as pkgs.website so nix-audit's bump report can watch it.
      nixpkgs.overlays = [
        (_: prev: {
          website = inputs.website.packages.${prev.stdenv.hostPlatform.system}.default;
        })
      ];

      services.nginx.virtualHosts.${domainName} = {
        forceSSL = true;
        useACMEHost = domainName;
        root = "${pkgs.website}";

        # Astro emits content-hashed assets here
        locations."/_astro/".extraConfig = ''
          add_header Cache-Control "public, max-age=31536000, immutable";
        '';
      };
    };
}
