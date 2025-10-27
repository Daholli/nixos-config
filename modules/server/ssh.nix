{
  flake.modules.nixos.server =
    { ... }:
    {
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
