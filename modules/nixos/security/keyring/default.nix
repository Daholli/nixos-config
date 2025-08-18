{
  options,
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.keyring;
in
{
  options.${namespace}.security.keyring = {
    enable = mkBoolOpt true "Whether to enable gnome keyring.";
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm.enableGnomeKeyring = true;
    security.pam.services.sddm.enableGnomeKeyring = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    services.dbus.packages = [
      pkgs.gnome-keyring
      pkgs.gcr
    ];

    environment.systemPackages = [ pkgs.seahorse ];
  };
}
