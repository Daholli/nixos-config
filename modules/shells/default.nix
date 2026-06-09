{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      devenv.shells = {
        default = {
          packages = with pkgs; [ atool ];
          enterShell = config.pre-commit.installationScript;
        };

        zig = {
          packages = [
            inputs.zig-flake.packages.${system}.nightly
            inputs.zls.packages.${system}.zls
          ];
        };
      };
    };
}
