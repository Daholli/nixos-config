{ withSystem, ... }:
{
  flake.modules.nixos.prometheus-exporters =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      exporters = config.services.prometheus.exporters;
      adguard = config.services.adguardhome;
      adguardExporterPort = 9618;
      synapseMetricsPort = 9009;
    in
    {
      services.prometheus.exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "processes"
          ];
        };

        unbound = lib.mkIf config.services.unbound.enable {
          enable = true;
          unbound.host = "unix://${config.services.unbound.localControlSocketPath}";
        };

        nginx.enable = config.services.nginx.enable;

        postgres = lib.mkIf config.services.postgresql.enable {
          enable = true;
          runAsLocalSuperUser = true;
        };
      };

      services.nginx.statusPage = lib.mkIf config.services.nginx.enable true;

      services.matrix-synapse.settings = lib.mkIf config.services.matrix-synapse.enable {
        enable_metrics = true;
        listeners = [
          {
            port = synapseMetricsPort;
            bind_addresses = [ "0.0.0.0" ];
            type = "metrics";
            tls = false;
            resources = [ ];
          }
        ];
      };

      systemd.services.prometheus-adguard-exporter = lib.mkIf adguard.enable {
        description = "Prometheus exporter for AdGuard Home";
        wantedBy = [ "multi-user.target" ];
        after = [ "adguardhome.service" ];
        environment = {
          ADGUARD_SERVERS = "http://${adguard.host}:${toString adguard.port}";
          # AdGuard Home has no users configured, but the exporter requires credentials.
          ADGUARD_USERNAMES = "prometheus";
          ADGUARD_PASSWORDS = "unused";
          BIND_ADDR = ":${toString adguardExporterPort}";
        };
        serviceConfig = {
          ExecStart = lib.getExe (
            withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.adguard-exporter)
          );
          DynamicUser = true;
          Restart = "on-failure";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.flatten [
        exporters.node.port
        (lib.optional exporters.unbound.enable exporters.unbound.port)
        (lib.optional exporters.nginx.enable exporters.nginx.port)
        (lib.optional exporters.postgres.enable exporters.postgres.port)
        (lib.optional config.services.matrix-synapse.enable synapseMetricsPort)
        (lib.optional adguard.enable adguardExporterPort)
        (lib.optional config.services.forgejo.enable config.services.forgejo.settings.server.HTTP_PORT)
      ];
    };
}
