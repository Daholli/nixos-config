topLevel: {
  flake.modules = {
    nixos.root =
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
                root
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

    homeManager.root =
      {
        lib,
        osConfig,
        pkgs,
        ...
      }:
      let

        generateHostEntry = machine: ''
          Host ${machine.hostName}
            IdentitiesOnly yes
            IdentityFile ${machine.sshKey}
            User remotebuild
        '';

        filteredMachines = lib.filter (machine: machine.hostName != "localhost") osConfig.nix.buildMachines;
        remotebuild-ssh-config = pkgs.writeTextFile {
          name = "remotebuild-ssh-config";
          text = lib.concatMapStringsSep "\n" generateHostEntry filteredMachines;
        };
      in
      {
        home.file = {
          ".ssh/config".source = remotebuild-ssh-config;
        };
      };
  };
}
