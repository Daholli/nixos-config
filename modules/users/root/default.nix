topLevel: {
  flake = {
    modules.nixos.root =
      { config, pkgs, ... }:
      {
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
