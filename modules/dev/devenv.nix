{
  flake.modules.nixos.dev =
    { inputs, pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv
      ];
    };
}
