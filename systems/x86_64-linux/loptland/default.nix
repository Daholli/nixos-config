{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  domainName = "christophhollizeck.dev";
  forgejoPort = 3000;
  hydraPort = 2000;

  cfg.enableAcme = true;

  sopsFile = lib.snowfall.fs.get-file "secrets/secrets-loptland.yaml";
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = [ ];

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
      "forgejo/runner/token" = {
        inherit sopsFile;
      };
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.fail2ban = {
    enable = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "git.${domainName}" = {
        forceSSL = cfg.enableAcme;
        useACMEHost = mkIf cfg.enableAcme domainName;

        locations."/" = {
          proxyPass = "http://localhost:${toString forgejoPort}/";
        };
      };

      "hydra.${domainName}" = {
        forceSSL = cfg.enableAcme;
        useACMEHost = mkIf cfg.enableAcme domainName;

        locations."/" = {
          proxyPass = "http://localhost:${toString hydraPort}/";
        };
      };

      "${domainName}" = {
        forceSSL = cfg.enableAcme;
        useACMEHost = mkIf cfg.enableAcme domainName;

        locations."/" = {
          root = /var/www/website;
          index = "index.html";
        };
      };

      "_" = {
        forceSSL = cfg.enableAcme;
        useACMEHost = mkIf cfg.enableAcme domainName;

        locations."/" = {
          proxyPass = "https://${domainName}";
        };
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
  };

  services.hydra = {
    enable = true;
    hydraURL = "http://localhost:${toString hydraPort}";
    port = hydraPort;
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
  };

  # services.gitea-actions-runner = {
  #   package = pkgs.forgejo-actions-runner;
  #   instances.default = {
  #     enable = true;
  #     name = "monolith";
  #     url = "https://git.${domainName}";
  #     tokenFile = config.sops.secrets."forgejo/runner/token".path;
  #     labels = [
  #       "native:host"
  #     ];
  #     hostPackages = with pkgs; [
  #       bash
  #       coreutils
  #       curl
  #       gawk
  #       gitMinimal
  #       gnused
  #       nodejs
  #       wget
  #     ];
  #     settings = {
  #       log.level = "info";
  #       runner = {
  #         capacity = 1;
  #         timeout = "3h";
  #         shutdown_timeout = "3s";
  #         fetch_timeout = "5s";
  #         fetch_inteval = "2s";
  #       };
  #     };
  #   };
  # };

  networking.firewall.allowedTCPPorts = [
    forgejoPort
    80
    443
  ];

  ${namespace} = {
    submodules = {
      basics = enabled;
    };

    services = {
      factorio-server = {
        enable = true;
        inherit sopsFile;
      };
    };

    security = {
      acme = {
        enable = cfg.enableAcme;
        inherit sopsFile;
      };
    };

    user.trustedPublicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0" # yggdrasil
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4Pr7p0jizrvIl0UhcvrmL5SHRQQQWIcHLAnRFyUZS6" # Phone
    ];
  };

  snowfallorg.users.${config.${namespace}.user.name}.home.config = {
    programs.fish.shellInit = ''
      eval $(op signin)
    '';
  };

  system.stateVersion = "24.11";
}
