{
  flake.modules.nixos.attic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # name -> public
      caches = {
        cholli = true;
        work = false;
      };
      port = 8181;

      upstreamCacheKeyNames = [
        "cache.nixos.org-1"
        "cache.lix.systems"
        "nix-community.cachix.org-1"
        "helix.cachix.org-1"
        "nixos-raspberrypi.cachix.org-1"
      ];

      configHome = pkgs.linkFarm "atticd-local-xdg" {
        "attic/config.toml" = (pkgs.formats.toml { }).generate "attic-local.toml" {
          default-server = "local";
          servers.local = {
            endpoint = "http://127.0.0.1:${toString port}/";
            token-file = config.sops.secrets."attic/token".path;
          };
        };
      };

      attic = "${pkgs.attic-client}/bin/attic";
    in
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
          listen = "127.0.0.1:${toString port}";
          api-endpoint = "https://attic.christophhollizeck.dev/";
          database.url = "postgresql:///atticd?host=/run/postgresql&user=atticd";
          garbage-collection.default-retention-period = "30 days";
        };
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "atticd" ];
        ensureUsers = [
          {
            name = "atticd";
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services.atticd-cache = {
        wantedBy = [ "multi-user.target" ];
        after = [ "atticd.service" ];
        requires = [ "atticd.service" ];
        partOf = [ "atticd.service" ];

        environment.XDG_CONFIG_HOME = configHome;

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 5;
          TimeoutStartSec = 120;
          DynamicUser = true;
          SupplementaryGroups = [ "secrets-access" ];
        };

        script = ''
          until (exec 3<>/dev/tcp/127.0.0.1/${toString port}) 2>/dev/null; do sleep 1; done
          ${lib.concatMapAttrsStringSep "\n" (name: public: ''
            ${attic} cache create ${name} || true
            ${attic} cache configure ${name} ${if public then "--public" else "--private"} \
              ${lib.concatMapStringsSep " " (k: "--upstream-cache-key-name ${k}") upstreamCacheKeyNames}
          '') caches}
        '';
      };
    };
}
