{
  flake.modules = {
    nixos.dev =
      { ... }:
      {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    homeManager.dev =
      { ... }:
      {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
  };
}
