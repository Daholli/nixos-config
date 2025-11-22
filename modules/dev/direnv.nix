{
  flake.modules = {
    nixos.dev =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.devenv ];

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
