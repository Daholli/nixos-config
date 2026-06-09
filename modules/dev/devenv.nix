{
  flake.modules = {
    nixos.dev =
      { inputs, pkgs, ... }:
      {
        environment.systemPackages = [ inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv ];
      };
    homeManager.dev = _: {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
