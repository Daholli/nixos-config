# nix-audit

## CycloneDX on demand

Reports no longer carry CycloneDX SBOMs or Sunshine links. To get one for a host:

```sh
nix develop .#nix-audit
sbomnix --cdx yggdrasil.cdx.json .#nixosConfigurations.yggdrasil.config.system.build.toplevel
grype sbom:yggdrasil.cdx.json -o cyclonedx-json > yggdrasil.vulns.cdx.json
```

`yggdrasil.vulns.cdx.json` holds the SBOM plus grype's findings; open it in
<https://cyclonedx.github.io/Sunshine/> via "Choose file".

## CPEs for flake-input packages

vulnxscan only knows a package's real CPE if sbomnix finds its derivation in
nixpkgs or in this flake's `legacyPackages`. Packages from other flake inputs
that set `meta.identifiers` need a line in `modules/flake-parts/cpe-packages.nix`,
keyed by their `pname`.
