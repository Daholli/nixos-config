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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  ${namespace} = {
    submodules = {
      basics = enabled;
    };

    services = {
      factorio-server = enabled;
    };

    user.trustedPublicKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0"
    ];

  };

  system.stateVersion = "24.11";
}
