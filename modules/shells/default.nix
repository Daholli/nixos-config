{
  inputs,
  ...
}:
{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [ atool ];
          shellHook = config.pre-commit.installationScript;
        };

        zig = pkgs.mkShell {
          packages = [
            inputs.zig-flake.packages.${pkgs.stdenv.hostPlatform.system}.nightly
            inputs.zls.packages.${pkgs.stdenv.hostPlatform.system}.zls
          ];
        };
      };
    };
}
