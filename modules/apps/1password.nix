topLevel: {
  flake.modules = {
    nixos._1password =
      { ... }:
      {
        programs = {
          _1password.enable = true;
          _1password-gui = {
            enable = true;
            polkitPolicyOwners = [ topLevel.config.flake.meta.users.cholli.username ];
          };
        };
      };

    homeManager.cholli =
      { lib, osConfig, ... }:
      {
        home.file = lib.mkIf osConfig.programs._1password.enable {
          ".ssh/config".text = ''
            Host *
             	ForwardAgent yes
            	IdentityAgent /home/cholli/.1password/agent.sock

            Host loptland
              Hostname christophhollizeck.dev
          '';
        };
      };
  };
}
