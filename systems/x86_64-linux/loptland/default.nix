{
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = [ pkgs.forgejo-cli ];

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
  };

  ${namespace} = {
    submodules = {
      basics = enabled;
    };

    services = {
      factorio-server = {
        enable = true;
        sopsFile = lib.snowfall.fs.get-file "secrets/secrets-loptland.yaml";
      };
    };

    user.trustedPublicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0"
    ];

  };

  system.stateVersion = "24.11";
}
