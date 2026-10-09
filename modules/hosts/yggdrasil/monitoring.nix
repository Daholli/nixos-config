{ withSystem, ... }:
{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixberry = "100.90.93.35";
      loptland = "100.86.250.97";
      scrapeInterval = "1m";

      job =
        name: targets: extra:
        {
          job_name = name;
          static_configs = map (t: {
            targets = [ t.target ];
            labels.instance = t.instance;
          }) targets;
        }
        // extra;

      grafanaDashboard =
        id: revision: hash:
        pkgs.fetchurl {
          name = "grafana-dashboard-${toString id}-${toString revision}.json";
          url = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString revision}/download";
          inherit hash;
        };

      adguardExporter = withSystem pkgs.stdenv.hostPlatform.system (
        { config, ... }: config.packages.adguard-exporter
      );

      dashboards = {
        node = grafanaDashboard 1860 45 "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
        postgres = grafanaDashboard 9628 8 "sha256-UhusNAZbyt7fJV/DhFUK4FKOmnTpG0R15YO2r+nDnMc=";
        nginx = grafanaDashboard 12708 1 "sha256-T1HqWbwt+i/We+Y2B7hcl3CijGxZF5QI38aPcXjk9y0=";
        unbound = grafanaDashboard 21006 4 "sha256-Z+y+8MCIpjgPW12Q2jcbNhaL/WA00SL2uPT/7KKsOVw=";
        adguard = "${adguardExporter}/share/grafana/dashboard.json";
        synapse = "${pkgs.matrix-synapse-unwrapped.src}/contrib/grafana/synapse.json";
      };

      dashboardDir = pkgs.runCommand "grafana-dashboards" { } (
        ''
          mkdir $out
        ''
        + lib.concatMapAttrsStringSep "\n" (name: src: ''
          sed 's/''${DS_PROMETHEUS}/prometheus/g' ${src} > $out/${name}.json
        '') dashboards
      );
    in
    {
      sops.secrets =
        lib.genAttrs
          [
            "grafana/admin_password"
            "grafana/secret_key"
          ]
          (_: {
            sopsFile = ../../../secrets/secrets-yggdrasil.yaml;
            owner = "grafana";
            restartUnits = [ "grafana.service" ];
          });

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
        extraSetFlags = [ "--accept-dns=false" ];
      };

      services.prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        retentionTime = "90d";
        globalConfig.scrape_interval = scrapeInterval;

        scrapeConfigs = [
          (job "node" [
            {
              target = "127.0.0.1:${toString config.services.prometheus.exporters.node.port}";
              instance = "yggdrasil";
            }
            {
              target = "${nixberry}:9100";
              instance = "nixberry";
            }
            {
              target = "${loptland}:9100";
              instance = "loptland";
            }
          ] { })
          (job "unbound" [
            {
              target = "${nixberry}:9167";
              instance = "nixberry";
            }
            {
              target = "${loptland}:9167";
              instance = "loptland";
            }
          ] { })
          (job "adguard" [
            {
              target = "${nixberry}:9618";
              instance = "nixberry";
            }
          ] { })
          (job "nginx" [
            {
              target = "${loptland}:9113";
              instance = "loptland";
            }
          ] { })
          (job "postgres" [
            {
              target = "${loptland}:9187";
              instance = "loptland";
            }
            {
              target = "${nixberry}:9187";
              instance = "nixberry";
            }
          ] { })
          (job "synapse" [
            {
              target = "${loptland}:9009";
              instance = "loptland";
            }
          ] { metrics_path = "/_synapse/metrics"; })
          (job "forgejo" [
            {
              target = "${loptland}:3000";
              instance = "loptland";
            }
          ] { })
        ];
      };

      services.grafana = {
        enable = true;
        declarativePlugins = [ pkgs.grafanaPlugins.prometheus ];
        settings = {
          plugins.preinstall_disabled = true;
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
          };
          security = {
            secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
            admin_password = "$__file{${config.sops.secrets."grafana/admin_password".path}}";
          };
          analytics.reporting_enabled = false;
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              isDefault = true;
              jsonData.timeInterval = scrapeInterval;
            }
          ];
          dashboards.settings.providers = [
            {
              name = "nix";
              options.path = dashboardDir;
            }
          ];
        };
      };

      systemd.services.grafana.serviceConfig = {
        StateDirectory = "grafana";
        StateDirectoryMode = "0700";
      };

    };
}
