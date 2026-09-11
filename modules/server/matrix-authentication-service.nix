{
  flake.modules.nixos.matrix-authentication-service =
    { config, ... }:
    let
      domainName = "alwayssleepy.online";
      sopsFile = ../../secrets/secrets-loptland.yaml;

      # Expanded by the module's envsubst pass over the generated config.
      cred = name: "\${CREDENTIALS_DIRECTORY}/${name}";
    in
    {
      sops.secrets = {
        "matrix/mas/encryption" = { inherit sopsFile; };
        "matrix/mas/signingKeyRsa" = { inherit sopsFile; };

        # Synapse reads this one directly; MAS reads it as root before dropping
        # to its DynamicUser.
        "matrix/mas/synapseSharedSecret" = {
          inherit sopsFile;
          owner = "matrix-synapse";
        };
      };

      # syn2mas and manage subcommands have to be run on the host.
      environment.systemPackages = [ config.services.matrix-authentication-service.package ];

      services.matrix-authentication-service = {
        enable = true;
        createDatabase = true;

        credentials = {
          encryption = config.sops.secrets."matrix/mas/encryption".path;
          signingKeyRsa = config.sops.secrets."matrix/mas/signingKeyRsa".path;
          synapseSharedSecret = config.sops.secrets."matrix/mas/synapseSharedSecret".path;
        };

        settings = {
          http = {
            public_base = "https://auth.${domainName}/";
            listeners = [
              {
                name = "web";
                resources = [
                  { name = "discovery"; }
                  { name = "human"; }
                  { name = "oauth"; }
                  { name = "compat"; }
                  { name = "graphql"; }
                  { name = "assets"; }
                ];
                binds = [
                  {
                    host = "127.0.0.1";
                    port = 8080;
                  }
                ];
              }
              {
                name = "internal";
                resources = [ { name = "health"; } ];
                binds = [
                  {
                    host = "127.0.0.1";
                    port = 8081;
                  }
                ];
              }
            ];
          };

          secrets = {
            encryption_file = cred "encryption";
            keys = [
              {
                kid = "rsa";
                key_file = cred "signingKeyRsa";
              }
            ];
          };

          # syn2mas imports Synapse's bcrypt hashes; v2 upgrades them to argon2id
          # on next login. Dropping v1 would invalidate every migrated password.
          passwords = {
            enabled = true;
            schemes = [
              {
                version = 1;
                algorithm = "bcrypt";
                unicode_normalization = true;
              }
              {
                version = 2;
                algorithm = "argon2id";
              }
            ];
          };

          matrix = {
            kind = "synapse";
            homeserver = domainName;
            endpoint = "http://localhost:8008";
            secret_file = cred "synapseSharedSecret";
          };
        };
      };
    };
}
