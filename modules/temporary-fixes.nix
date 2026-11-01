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

    # NixOS/nixpkgs#576874: azure-cli needs fabric, which is broken with invoke 3.
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
        azure-cli =
          if !(prev.python3Packages.fabric.meta.broken or false) then
            prev.azure-cli
          else
            prev.azure-cli.override {
              python3 = prev.python3 // {
                override =
                  args:
                  prev.python3.override (
                    args
                    // {
                      packageOverrides = lib.composeExtensions (args.packageOverrides or (_: _: { })) pinInvoke;
                    }
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

    (final: prev: {
      vlc =
        if lib.functionArgs prev.vlc.override ? ffmpeg_8 then
          prev.vlc.override { ffmpeg_8 = final.ffmpeg; }
        else
          prev.vlc;
    })
  ];
in
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs { inherit system overlays; };
    };

  flake.modules.nixos.base.nixpkgs.overlays = overlays;

}
