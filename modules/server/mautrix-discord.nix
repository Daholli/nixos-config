{
  flake.modules.nixos.mautrix-discord =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      matrixDomain = "alwayssleepy.online";
      bridgePort = 29334;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      sops.secrets."matrix/mautrix-discord/botToken" = {
        inherit sopsFile;
        owner = "mautrix-discord";
      };

      sops.templates."mautrix-discord.env" = {
        owner = "mautrix-discord";
        content = ''
          MAUTRIX_DISCORD_DISCORD_BOT_TOKEN=${config.sops.placeholder."matrix/mautrix-discord/botToken"}
        '';
      };

      services.postgresql = {
        ensureDatabases = [ "mautrix-discord" ];
        ensureUsers = [
          {
            name = "mautrix-discord";
            ensureDBOwnership = true;
          }
        ];
      };

      # mautrix-discord (like matrix-synapse) requires C collation
      systemd.services."mautrix-discord-db-setup" = {
        description = "Set up mautrix-discord PostgreSQL database with C collation";
        wantedBy = [ "mautrix-discord.service" ];
        before = [ "mautrix-discord.service" ];
        after = [
          "postgresql.service"
          "postgresql-setup.service"
        ];
        requires = [ "postgresql.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "postgres";
          RemainAfterExit = true;
        };
        script =
          let
            psql = lib.getExe' pkgs.postgresql "psql";
          in
          ''
            COLLATION=$(${psql} -tAc "SELECT datcollate FROM pg_database WHERE datname = 'mautrix-discord'")
            if [ "$COLLATION" != "C" ]; then
              ${psql} -c "DROP DATABASE \"mautrix-discord\""
              ${psql} -c "CREATE DATABASE \"mautrix-discord\" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE=template0 OWNER \"mautrix-discord\""
            fi
          '';
      };

      # mautrix-discord depends on libolm which is deprecated/insecure upstream.
      nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

      services.mautrix-discord = {
        enable = true;
        environmentFile = config.sops.templates."mautrix-discord.env".path;

        settings = {
          homeserver = {
            address = "http://localhost:${toString 8008}";
            domain = matrixDomain;
          };

          appservice = {
            address = "http://localhost:${toString bridgePort}";
            hostname = "127.0.0.1";
            port = bridgePort;
            database = {
              type = "postgres";
              uri = "postgres:///mautrix-discord?host=/var/run/postgresql";
            };
          };

          bridge = {
            relay = {
              enabled = true;
              admin_only = false;
            };

            permissions = {
              "@cholli:${matrixDomain}" = "admin";
              "${matrixDomain}" = "user";
            };
          };
        };
      };

      # Give matrix-synapse access to the registration file via group membership
      users.users.matrix-synapse.extraGroups = [ "mautrix-discord" ];
    };
}
