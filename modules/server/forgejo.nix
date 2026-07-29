{
  flake.modules.nixos.forgejo =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      domainName = "christophhollizeck.dev";
      forgejoPort = 3000;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      imports = [
        inputs.simple-nixos-mailserver.nixosModules.default
      ];

      catppuccin.forgejo.enable = true;

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
          # SSH-format instance signing key: forgejo signs its own commits
          # (web-based merges, wiki edits, CRUD actions) with this. Forgejo
          # needs to read the private key straight off disk as the forgejo
          # user, so unlike the other secrets above it can't go through the
          # LoadCredential-based `services.forgejo.secrets` mechanism.
          # https://forgejo.org/docs/latest/admin/advanced/signing/
          "forgejo/signing/key" = {
            inherit sopsFile;
            owner = "forgejo";
            mode = "0400";
          };
          # Must resolve to the private key's path with ".pub" appended;
          # that's what Forgejo requires for FORMAT = "ssh".
          "forgejo/signing/key.pub" = {
            inherit sopsFile;
            owner = "forgejo";
            mode = "0400";
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

          "repository.signing" = {
            FORMAT = "ssh";
            SIGNING_KEY = config.sops.secrets."forgejo/signing/key.pub".path;
            SIGNING_NAME = "Forgejo";
            SIGNING_EMAIL = "no-reply@${domainName}";
          };
        };

        secrets = {
          mailer.PASSWD = config.sops.secrets."forgejo/mail/password".path;
        };
      };

      # ssh-keygen (for SSH-format commit signing) isn't otherwise pulled
      # into forgejo's unit PATH.
      systemd.services.forgejo.path = [ pkgs.openssh ];

      mailserver = {
        enable = false;
        fqdn = "mail.${domainName}";
        domains = [ domainName ];

        accounts = {
          "forgejo@${domainName}" = {
            hashedPasswordFile = config.sops.secrets."forgejo/mail/passwordHash".path;
            aliases = [ "no-reply@${domainName}" ];
          };
        };

        x509 = {
          useACMEHost = domainName;
        };
        stateVersion = 3;
      };

    };
}
