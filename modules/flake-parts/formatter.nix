{
  inputs,
  ...
}:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem = { config, ... }: {
    pre-commit = {
      check.enable = false;
      settings.hooks.treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };
    };

    treefmt.imports = [ ./_treefmt.nix ];
  };
}
