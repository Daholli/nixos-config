{
  flake.modules.nixos.dev =
    { inputs, pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.devenv.packages.${pkgs.system}.devenv
      ];
    };
}
