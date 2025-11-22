{
  flake.modules.nixos.forgejo =
    { config, inputs, ... }:
    let
      domainName = "christophhollizeck.dev";
      forgejoPort = 3000;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      imports = [
        inputs.simple-nixos-mailserver.nixosModules.default
      ];

      sops = {
        secrets = {
          "forgejo/db/password" = {
            inherit sopsFile;
          };
          "forgejo/mail/password" = {
            inherit sopsFile;
          };
          "forgejo/mail/passwordHash" = {
            inherit sopsFile;
          };
        };
      };

      services.forgejo = {
        enable = true;
        database.type = "postgres";
        lfs.enable = true;
        database = {
          passwordFile = config.sops.secrets."forgejo/db/password".path;
        };

        settings = {
          server = {
            DOMAIN = "git.${domainName}";
            ROOT_URL = "https://git.${domainName}";
            HTTP_PORT = forgejoPort;
          };

          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
            FROM = "no-reply@${domainName}";
            SMTP_ADDR = "mail.${domainName}";
            USER = "forgejo@${domainName}";
          };

          service.DISABLE_REGISTRATION = true;
        };

        secrets = {
          mailer.PASSWD = config.sops.secrets."forgejo/mail/password".path;
        };
      };

      mailserver = {
        enable = true;
        fqdn = "mail.${domainName}";
        domains = [ domainName ];

        loginAccounts = {
          "forgejo@${domainName}" = {
            hashedPasswordFile = config.sops.secrets."forgejo/mail/passwordHash".path;
            aliases = [ "no-reply@${domainName}" ];
          };
        };

        certificateScheme = "acme-nginx";
        stateVersion = 3;
      };

    };
}
