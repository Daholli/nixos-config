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

    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        deadnix.enable = true;
        jsonfmt.enable = true;
        nixfmt.enable = true;
        prettier.enable = true;
        qmlformat.enable = true;
        ruff-format.enable = true;
        rustfmt.enable = true;
        shfmt.enable = true;
        statix.enable = true;
        yamlfmt.enable = true;
      };
      settings = {
        on-unmatched = "fatal";
        global.excludes = [
          "*.envrc"
          ".editorconfig"
          "*.csv"
          "*.directory"
          "*.face"
          "*.fish"
          "*.png"
          "*.jpg"
          "*.jpeg"
          "*.toml"
          "*.svg"
          "*.xml"
          "*/.gitignore"
          "_to_migrate/*"
          "secrets/*"
          "LICENSE"
        ];
      };
    };
  };
}
