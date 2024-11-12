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

      "${domainName}" = {
        forceSSL = cfg.enableAcme;
        useACMEHost = mkIf cfg.enableAcme domainName;

        locations."/" = {
          return = "404";
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

      service.DISABLE_REGISTRATION = true;
    };
  };

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
