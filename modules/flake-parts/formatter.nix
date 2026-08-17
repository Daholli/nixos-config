{
  inputs,
  ...
}:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = _: {
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
