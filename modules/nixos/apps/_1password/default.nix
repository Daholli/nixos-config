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
  username = config.${namespace}.user.name;
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
        polkitPolicyOwners = [ username ];
      };
    };

    ${namespace}.home.file.".ssh/config".text = ''
      Host *
       	ForwardAgent yes
      	IdentityAgent /home/${username}/.1password/agent.sock

      Host loptland
        Hostname christophhollizeck.dev
    '';
  };
}
