{
  perSystem =
    { pkgs, ... }:
    {
      packages.adguard-exporter = pkgs.buildGoModule (finalAttrs: {
        pname = "adguard-exporter";
        version = "1.2.1";

        src = pkgs.fetchFromGitHub {
          owner = "henrywhitaker3";
          repo = "adguard-exporter";
          tag = "v${finalAttrs.version}";
          hash = "sha256-OltYzxBOOcaW3oYNFvxxjG1qRvuLaZfReSeQaNGiRDc=";
        };

        vendorHash = "sha256-fDSR0+INsVBD5XauPdSETMNJZkrIbpKwZ/6Tb2Po4fY=";

        postInstall = ''
          install -Dm644 grafana/*.json -t $out/share/grafana
        '';

        meta = {
          description = "Prometheus exporter for AdGuard Home";
          homepage = "https://github.com/henrywhitaker3/adguard-exporter";
          license = pkgs.lib.licenses.mit;
          mainProgram = "adguard-exporter";
        };
      });
    };
}
