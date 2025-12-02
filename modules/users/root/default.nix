topLevel: {
  flake = {
    modules.nixos.root =
      {
        config,
        inputs,
        pkgs,
        ...
      }:
      {
        imports = [
          {
            home-manager.users.root = {
              imports = with topLevel.config.flake.modules.homeManager; [
                inputs.catppuccin.homeModules.catppuccin

                # components
                base

                # Activate all user based config
                cholli # TODO: make root based config that makes it clear I am root user right now
              ];
            };
          }
        ];
        programs.fish.enable = true;
        sops.secrets.passwordHash.neededForUsers = true;

        users.users.root = {
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = topLevel.config.flake.meta.users.cholli.authorizedKeys;
          hashedPasswordFile = config.sops.secrets.passwordHash.path;
        };
      };
  };
}
