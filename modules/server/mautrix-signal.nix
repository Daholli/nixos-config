{
  flake.modules.nixos.mautrix-signal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      matrixDomain = "alwayssleepy.online";
      bridgePort = 29335;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      services.postgresql = {
        ensureDatabases = [ "mautrix-signal" ];
        ensureUsers = [
          {
            name = "mautrix-signal";
            ensureDBOwnership = true;
          }
        ];
      };

      # mautrix-signal (like matrix-synapse) requires C collation
      systemd.services."mautrix-signal-db-setup" = {
        description = "Set up mautrix-signal PostgreSQL database with C collation";
        wantedBy = [ "mautrix-signal.service" ];
        before = [ "mautrix-signal.service" ];
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
            COLLATION=$(${psql} -tAc "SELECT datcollate FROM pg_database WHERE datname = 'mautrix-signal'")
            if [ "$COLLATION" != "C" ]; then
              ${psql} -c "DROP DATABASE \"mautrix-signal\""
              ${psql} -c "CREATE DATABASE \"mautrix-signal\" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE=template0 OWNER \"mautrix-signal\""
            fi
          '';
      };

      services.mautrix-signal = {
        enable = true;

        settings = {
          homeserver = {
            address = "http://localhost:${toString 8008}";
            domain = matrixDomain;
          };

          appservice = {
            address = "http://localhost:${toString bridgePort}";
            hostname = "127.0.0.1";
            port = bridgePort;
          };

          database = {
            type = "postgres";
            uri = "postgres:///mautrix-signal?host=/var/run/postgresql";
          };

          bridge = {
            permissions = {
              "@cholli:${matrixDomain}" = "admin";
              "${matrixDomain}" = "user";
            };
          };
        };
      };
    };
}
