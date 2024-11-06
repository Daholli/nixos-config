{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  sopsFile = lib.snowfall.fs.get-file "secrets/secrets-loptland.yaml";
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = [ pkgs.forgejo-cli ];

  sops.secrets = {
    domain = {
      inherit sopsFile;
    };

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

  services.forgejo = {
    enable = true;
    lfs.enable = true;
    database = {
      passwordFile = config.sops.secrets.forgejo_db_password.path;
    };
    # settings = {
    #   server.DOMAIN = config.sops.secrets.domain;
    # };

  };

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
