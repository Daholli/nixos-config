topLevel: {
  flake.modules = {
    homeManager.cholli = _: {
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = topLevel.config.flake.meta.users.cholli.name;
            email = topLevel.config.flake.meta.users.cholli.email;
          };
          signing = {
            behavior = "own";
            backend = "gpg";
            key = topLevel.config.flake.meta.users.cholli.key;
          };
        };
      };
    };
  };
}
