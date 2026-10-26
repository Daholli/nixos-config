# Workarounds for upstream breakage. Each block names the upstream fix; delete
# it once that fix reaches nixos-unstable.
{ inputs, lib, ... }:
let
  pythonFix = f: _: prev: { pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [ f ]; };

  overlays = [
    # NixOS/nixpkgs#573108: typepy 2 breaks sqliteschema/simplesqlite (sbomnix)
    (pythonFix (
      _: pyPrev: {
        sqliteschema = pyPrev.sqliteschema.overridePythonAttrs { pythonRelaxDeps = [ "typepy" ]; };
        simplesqlite = pyPrev.simplesqlite.overridePythonAttrs { pythonRelaxDeps = [ "typepy" ]; };
      }
    ))

    # NixOS/nixpkgs#576194: sphinxHook only runs the first builder (reuse misses its man output)
    (pythonFix (
      _: pyPrev: {
        reuse = pyPrev.reuse.overridePythonAttrs { sphinxBuilders = "html man"; };
      }
    ))

    # NixOS/nixpkgs#576742: azure-cli needs fabric, which is broken with invoke 3.
    # Pin invoke inside azure-cli's own python set only; globally it rebuilds aiohttp and up.
    (
      _: prev:
      let
        pinInvoke = _: pyPrev: {
          invoke = pyPrev.invoke.overridePythonAttrs (old: rec {
            version = "2.2.1";
            src = pyPrev.fetchPypi {
              inherit (old) pname;
              inherit version;
              hash = "sha256-UVv0m0pIkyt5sCRZA0jaIvOcSULf+ZGtH7i4uuob5wc=";
            };
          });
        };
      in
      {
        azure-cli = prev.azure-cli.override {
          python3 = prev.python3 // {
            override =
              args:
              prev.python3.override (
                args // { packageOverrides = lib.composeExtensions args.packageOverrides pinInvoke; }
              );
          };
        };
      }
    )

    # NixOS/nixpkgs#576284: sbomnix makeWrapperArgs break under structured attrs
    (_: prev: {
      sbomnix = prev.sbomnix.overridePythonAttrs (old: {
        makeWrapperArgs = lib.concatMap (lib.splitString " ") old.makeWrapperArgs;
      });
    })

    # vlc still pins ffmpeg_7 (CVEs) although 3.0.24 upstream ships ffmpeg 8; libvlc inherits this
    (final: prev: { vlc = prev.vlc.override { ffmpeg_7 = final.ffmpeg; }; })
  ];
in
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs { inherit system overlays; };
    };

  flake.modules.nixos.base.nixpkgs.overlays = overlays;

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    let
      llmPkgs = inputs.llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      _module.args.llmPkgs = lib.mkForce (
        llmPkgs
        // {
          # patchelf 0.19 corrupts the Node SEA when setting the rpath; the
          # wrapper already sets LD_LIBRARY_PATH (no upstream fix yet)
          copilot-cli = llmPkgs.copilot-cli.overrideAttrs (old: {
            installPhase = lib.concatStrings (
              lib.filter lib.isString (builtins.split ''--set-rpath "[^"]*"'' old.installPhase)
            );
          });
        }
      );
    };
}
