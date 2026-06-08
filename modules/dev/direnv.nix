{
  flake.modules = {
    nixos.dev =
      { inputs, pkgs, ... }:
      {
        environment.systemPackages = [ inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    homeManager.dev = _: {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
