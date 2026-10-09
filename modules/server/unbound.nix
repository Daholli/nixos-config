{
  flake.modules.nixos.unbound-resolver =
    { config, lib, ... }:
    let
      cfg = config.local.unbound;
    in
    {
      options.local.unbound = {
        interfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "127.0.0.1" ];
          description = "Addresses Unbound listens on.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 53;
        };
        allowedNetworks = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "127.0.0.0/8" ];
          description = "Client networks allowed to query; everything else is refused.";
        };
        ipv6 = lib.mkEnableOption "IPv6 transport towards authoritative servers";
        threatFeed = lib.mkEnableOption "HaGeZi Threat Intelligence Feed (RPZ) blocking";
      };

      config = {
        services.unbound = {
          enable = true;
          resolveLocalQueries = false;
          localControlSocketPath = "/run/unbound/unbound.ctl";
          settings = {
            server = {
              interface = cfg.interfaces;
              inherit (cfg) port;
              do-ip4 = true;
              do-ip6 = cfg.ipv6;
              do-udp = true;
              do-tcp = true;
              access-control = map (net: "${net} allow") cfg.allowedNetworks ++ [
                "0.0.0.0/0 refuse"
                "::0/0 refuse"
              ];
              hide-identity = true;
              hide-version = true;
              harden-glue = true;
              harden-dnssec-stripped = true;
              harden-below-nxdomain = true;
              harden-referral-path = true;
              qname-minimisation = true;
              private-address = [
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
                "169.254.0.0/16"
                "fd00::/8"
                "fe80::/10"
              ];
              msg-cache-size = "64m";
              rrset-cache-size = "128m";
              msg-cache-slabs = 4;
              rrset-cache-slabs = 4;
              infra-cache-slabs = 4;
              key-cache-slabs = 4;
              prefetch = true;
              prefetch-key = true;
              num-threads = 4;
              so-rcvbuf = "1m";
              edns-buffer-size = 1232;
              extended-statistics = true;
            }
            // lib.optionalAttrs cfg.threatFeed {
              module-config = ''"respip validator iterator"'';
              tls-cert-bundle = config.security.pki.caBundle;
            };

            rpz = lib.mkIf cfg.threatFeed [
              {
                name = "tif.hagezi";
                url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/tif.medium.txt";
                zonefile = "${config.services.unbound.stateDir}/tif.rpz";
                rpz-log = true;
                rpz-log-name = "tif";
              }
            ];
          };
        };
      };
    };
}
