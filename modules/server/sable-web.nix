{ inputs, ... }:
{
  flake.modules.nixos.sable-web =
    { lib, pkgs, ... }:
    let
      matrixDomain = "alwayssleepy.online";
      sable = inputs.sable.packages.${pkgs.stdenv.hostPlatform.system}.sable.override {
        # The upstream wrapper replaces config.json instead of merging into it.
        conf = lib.recursiveUpdate (lib.importJSON "${inputs.sable}/static/config.json") {
          homeserverList = [ matrixDomain ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          featuredCommunities.servers = [ ];
          calls.livekitServiceUrl = "https://call.${matrixDomain}/livekit/jwt";
        };
      };
      # The build writes its CSP, with hashes of the inline scripts, as a Caddy directive.
      csp = pkgs.runCommand "sable-csp.conf" { } ''
        sed -E 's/^header (Content-Security-Policy ".*")$/add_header \1 always;/' \
          ${sable}/csp.caddy > $out
        grep -q '^add_header Content-Security-Policy' $out
      '';
    in
    {
      services.nginx.virtualHosts."chat.${matrixDomain}" = {
        forceSSL = true;
        useACMEHost = matrixDomain;

        root = "${sable}";

        # Mirrors packaging/docker/Caddyfile: stale hashed assets must 404, not fall back.
        locations."/_app/".tryFiles = "$uri =404";
        locations."/_app/immutable/".extraConfig = ''
          add_header Cache-Control "public, max-age=31536000, immutable" always;
        '';

        locations."/" = {
          tryFiles = "$uri $uri.html $uri/index.html /index.html";
          extraConfig = ''
            add_header Cache-Control "no-cache" always;
            include ${csp};
          '';
        };

        locations."= /manifest.webmanifest".extraConfig = ''
          default_type application/manifest+json;
          add_header Cache-Control "no-cache" always;
        '';
      };
    };
}
