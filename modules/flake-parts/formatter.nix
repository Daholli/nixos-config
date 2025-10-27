{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    { self', ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          deadnix.enable = true;
          jsonfmt.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          yamlfmt.enable = true;
        };
        settings = {
          on-unmatched = "fatal";
          global.excludes = [
            "*.envrc"
            ".editorconfig"
            "*.directory"
            "*.face"
            "*.fish"
            "*.png"
            "*.toml"
            "*.svg"
            "*.xml"
            "*/.gitignore"
            "_to_migrate/*"
            "LICENSE"
          ];
        };
      };

      pre-commit.settings.hooks.nix-fmt = {
        enable = true;
        entry = lib.getExe self'.formatter;
      };
    };
}
