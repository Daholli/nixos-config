_: {
  perSystem =
    { config, pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            config.pre-commit.settings.package
            config.treefmt.build.wrapper
          ];
          shellHook = config.pre-commit.installationScript;
        };

        nix-audit = pkgs.mkShell {
          packages = with pkgs; [
            cargo
            clippy
            rust-analyzer
            rustc
            rustfmt

            nvd
            sbomnix
          ];

          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
          shellHook = config.pre-commit.installationScript;
        };
      };
    };
}
