{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.openssh;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.${namespace}.services.openssh = {
    enable = mkEnableOption "Enable SSH";
  };

  config = mkIf cfg.enable {
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
  };
}
