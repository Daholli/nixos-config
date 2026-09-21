_: {
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.nix-audit = pkgs.rustPlatform.buildRustPackage {
        pname = "nix-audit";
        version = "0.1.0";

        src = ./nix-audit;
        cargoLock.lockFile = ./nix-audit/Cargo.lock;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        # nix stays on the caller's PATH so the local lix and its settings keep control.
        postInstall = ''
          wrapProgram $out/bin/nix-audit \
            --prefix PATH : ${
              lib.makeBinPath (
                with pkgs;
                [
                  git
                  nvd
                  sbomnix
                ]
              )
            } \
            --set-default NIX_AUDIT_WHITELIST ${./vuln-whitelist.csv}
        '';

        meta = {
          description = "CVE and version-bump audit for NixOS system closures";
          license = lib.licenses.agpl3Plus;
          platforms = lib.platforms.linux;
          mainProgram = "nix-audit";
        };
      };
    };
}
