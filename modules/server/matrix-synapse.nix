{
  flake.modules.nixos.matrix-synapse =
    { config, pkgs, lib, ... }:
    let
      domainName = "alwayssleepy.online";
      matrixPort = 8008;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      sops.secrets."matrix/registrationSharedSecret" = {
        inherit sopsFile;
        owner = "matrix-synapse";
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "matrix-synapse" ];
        ensureUsers = [
          {
            name = "matrix-synapse";
            ensureDBOwnership = true;
          }
        ];
      };

      # ensureDatabases creates with default collation, but Synapse requires C collation.
      # This service runs after postgresql-setup (which runs ensureDatabases) and corrects
      # the collation by recreating the DB if needed.
      systemd.services."matrix-synapse-db-setup" = {
        description = "Set up Matrix Synapse PostgreSQL database with C collation";
        wantedBy = [ "matrix-synapse.service" ];
        before = [ "matrix-synapse.service" ];
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
          let psql = lib.getExe' pkgs.postgresql "psql"; in
          ''
            COLLATION=$(${psql} -tAc "SELECT datcollate FROM pg_database WHERE datname = 'matrix-synapse'")
            if [ "$COLLATION" != "C" ]; then
              ${psql} -c "DROP DATABASE \"matrix-synapse\""
              ${psql} -c "CREATE DATABASE \"matrix-synapse\" ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE=template0 OWNER \"matrix-synapse\""
            fi
          '';
      };

      services.matrix-synapse = {
        enable = true;

        settings = {
          server_name = domainName;

          database = {
            name = "psycopg2";
            args.database = "matrix-synapse";
          };

          public_baseurl = "https://matrix.${domainName}";

          listeners = [
            {
              port = matrixPort;
              bind_addresses = [ "127.0.0.1" ];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = false;
                }
              ];
            }
          ];

          enable_registration = true;
          registration_requires_token = true;
        };

        extraConfigFiles = [ config.sops.templates."matrix-synapse-extra.yaml".path ];
      };

      sops.templates."matrix-synapse-extra.yaml" = {
        owner = "matrix-synapse";
        content = ''
          registration_shared_secret: "${config.sops.placeholder."matrix/registrationSharedSecret"}"
        '';
      };
    };
}
