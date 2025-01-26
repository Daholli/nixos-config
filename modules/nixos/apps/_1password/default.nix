{
  config,
  lib,
  namespace,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps._1password;
in
{
  options.${namespace}.apps._1password = {
    enable = mkBoolOpt true "Enable 1Password";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ config.${namespace}.user.name ];
      };
    };

    ${namespace}.home.file.".ssh/config".text = ''
      Host *
       	ForwardAgent yes
      	IdentityAgent ~/.1password/agent.sock
    '';
  };
}
