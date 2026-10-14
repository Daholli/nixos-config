topLevel: {
  flake.modules = {
    homeManager.cholli =
      { lib, osConfig, ... }:
      {
        programs.jujutsu = {
          enable = true;
          settings = {
            user = {
              name = topLevel.config.flake.meta.users.cholli.name;
              email = topLevel.config.flake.meta.users.cholli.email;
            };
            signing = lib.mkIf osConfig.programs.gnupg.agent.enable {
              behavior = "own";
              backend = "gpg";
              key = topLevel.config.flake.meta.users.cholli.key;
            };
          };
        };
      };
  };
}
