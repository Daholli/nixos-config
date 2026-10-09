topLevel: {
  flake.modules.nixos."hosts/nixberry" =
    { config, ... }:
    let
      ipAddress = "192.168.178.2";
      fritzbox = "192.168.178.1";
      sopsFile = ../../../secrets/secrets-nixberry.yaml;
      dnsDomain = "dns.christophhollizeck.dev";
      certDir = config.security.acme.certs.${dnsDomain}.directory;
      unbound = "127.0.0.1:5335";
      loptlandUnbound = "100.86.250.97:53";
    in
    {
      sops = {
        secrets = {
          "netcup/customer_number" = {
            inherit sopsFile;
          };
          "netcup/api/key" = {
            inherit sopsFile;
          };
          "netcup/api/password" = {
            inherit sopsFile;
          };
        };

        templates."netcup.env".content = ''
          NETCUP_CUSTOMER_NUMBER=${config.sops.placeholder."netcup/customer_number"}
          NETCUP_API_KEY=${config.sops.placeholder."netcup/api/key"}
          NETCUP_API_PASSWORD=${config.sops.placeholder."netcup/api/password"}
          NETCUP_PROPAGATION_TIMEOUT=1200
        '';
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = topLevel.config.flake.meta.users.cholli.email;
        certs.${dnsDomain} = {
          dnsProvider = "netcup";
          environmentFile = config.sops.templates."netcup.env".path;
          dnsResolver = "1.1.1.1:53";
          extraDomainNames = [ "*.${dnsDomain}" ];
          reloadServices = [ "adguardhome.service" ];
        };
      };

      networking.firewall = {
        allowedTCPPorts = [
          53
          80
          443
          853
        ];
        allowedUDPPorts = [ 53 ];
      };

      local.unbound = {
        interfaces = [ "127.0.0.1" ];
        port = 5335;
        ipv6 = true;
      };

      systemd.services.adguardhome = {
        after = [ "unbound.service" ];
        wants = [ "unbound.service" ];
        serviceConfig.SupplementaryGroups = [ "acme" ];
      };

      services.adguardhome = {
        enable = true;
        mutableSettings = false;
        host = ipAddress;
        port = 80;

        settings = {
          http = {
            address = "0.0.0.0:80";
          };
          dns = {
            ratelimit = 0;
            bind_hosts = [ "0.0.0.0" ];
            upstream_dns = [
              loptlandUnbound
              "[/fritz.box/]${fritzbox}"
            ];
            fallback_dns = [ unbound ];
            bootstrap_dns = [ unbound ];
            local_ptr_upstreams = [ fritzbox ];
            use_private_ptr_resolvers = true;
            enable_dnssec = false;
            cache_size = 268435456;
          };
          tls = {
            enabled = true;
            server_name = dnsDomain;
            port_https = 443;
            port_dns_over_tls = 853;
            port_dns_over_quic = 0;
            allow_unencrypted_doh = false;
            certificate_path = "${certDir}/fullchain.pem";
            private_key_path = "${certDir}/key.pem";
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
            rewrites =
              map
                (domain: {
                  inherit domain;
                  answer = ipAddress;
                  enabled = true;
                })
                [
                  "nixberry.fritz.box"
                  "nixberry"
                  dnsDomain
                  "*.${dnsDomain}"
                ];
          };

          user_rules = [
            "||qognify.sysaidit.com^$important"
            "||*.live.darktracesensor.com^$important"
          ];

          filters =
            map
              (url: {
                enabled = true;
                inherit url;
              })
              [
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt" # AdGuard Dns filter
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt" # AdGuard Dns PopupHosts filter
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt" # The Big List of Hacked Malware Web Sites
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt" # malicious url blocklist
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt" # Phishing
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt"
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt"
                "https://big.oisd.nl"
              ];

          statistics = {
            enabled = true;
            interval = "8760h";
          };
          clients = {
            persistent = [
              {
                name = "yggdrasil";
                ids = [ "192.168.178.51" ];
                tags = [
                  "device_pc"
                  "os_linux"
                ];
                uid = "019aac26-684c-7c2c-a43d-2253f4407d45";
                use_global_settings = true;
              }
              {
                name = "holli - phone";
                ids = [
                  "192.168.178.52"
                  "100.124.47.76"
                  "fd7a:115c:a1e0::b701:2f4f"
                ];
                tags = [
                  "device_phone"
                  "os_android"
                ];
                uid = "019aeb6c-62bf-7a55-a549-45e17b14ef64";
                use_global_settings = true;
              }
              {
                name = "nixberry";
                ids = [
                  "192.168.178.2"
                  "100.90.93.35"
                  "fd7a:115c:a1e0::dd01:5d34"
                ];
                tags = [
                  "device_pc"
                  "os_linux"
                ];
                uid = "019aac5a-760e-73f9-a246-3470dae6219d";
                use_global_settings = true;
              }
              {
                name = "work-laptop";
                ids = [ "192.168.178.48" ];
                tags = [
                  "device_pc"
                  "os_windows"
                ];
                uid = "019aac55-ae29-7c5e-aac0-baadd7157f92";
                use_global_settings = true;
              }
            ];
          };
        };
      };
    };
}
