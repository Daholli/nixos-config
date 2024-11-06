{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  domainName = "v2202411240203293899.ultrasrv.de";
  forgejoPort = 3000;

  sopsFile = lib.snowfall.fs.get-file "secrets/secrets-loptland.yaml";
in
{
  imports = [ ./hardware.nix ];

  sops.secrets = {
    forgejo_db_password = {
      inherit sopsFile;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "git.${domainName}" = {
        locations."/" = {
          proxyPass = "http://localhost:${toString forgejoPort}/";
        };
      };

      "${domainName}" = {
        locations."/" = {
          return = "404 This Site does not exist yet";
        };
      };
    };

  };

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;
    database = {
      passwordFile = config.sops.secrets.forgejo_db_password.path;
    };
    settings = {
      server = {
        DOMAIN = "git.${domainName}";
        ROOT_URL = "http://git.${domainName}:${toString forgejoPort}";
        HTTP_PORT = forgejoPort;
      };

      service.DISABLE_REGISTRATION = false;
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

    user.trustedPublicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0"
    ];

  };

  system.stateVersion = "24.11";
}
