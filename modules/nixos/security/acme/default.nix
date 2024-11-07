{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.security.acme;
in
{
  options.${namespace}.security.acme = with lib.types; {
    enable = mkEnableOption "Enable sops (Default true)";
    email = mkOpt str config.${namespace}.user.email "The email to use.";
    sopsFile = mkOption {
      type = lib.types.path;
      default = lib.snowfall.fs.get-file "secrets/secrets.yaml";
      description = "SecretFile";
    };
    domainname = mkOpt str "christophhollizeck.dev" "domainname to use";
    staging = mkOpt bool false "Use staging server for testing or not";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        netcup_customer_number = {
          inherit (cfg) sopsFile;
        };

        netcup_api_key = {
          inherit (cfg) sopsFile;
        };

        netcup_api_password = {
          inherit (cfg) sopsFile;
        };
      };

      templates = {
        "netcup.env" = {
          content = ''
            NETCUP_CUSTOMER_NUMBER=${config.sops.placeholder.netcup_customer_number}
            NETCUP_API_KEY=${config.sops.placeholder.netcup_api_key}
            NETCUP_API_PASSWORD=${config.sops.placeholder.netcup_api_password}
            NETCUP_PROPAGATION_TIMEOUT=1200
          '';
        };
      };

    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit (cfg) email;

        group = mkIf config.services.nginx.enable "nginx";
        reloadServices = optional config.services.nginx.enable "nginx.service";

        dnsProvider = "netcup";
        environmentFile = config.sops.templates."netcup.env".path;
      };

      certs."${cfg.domainname}" = {
        server = mkIf cfg.staging "https://acme-staging-v02.api.letsencrypt.org/directory";
        dnsResolver = "1.1.1.1:53";
        extraDomainNames = [ "*.${cfg.domainname}" ];
      };
    };

  };
}
