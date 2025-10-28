topLevel: {
  flake.modules.nixos.server =
    {
      config,
      lib,
      ...
    }:
    let
      sopsFile = ../../secrets/secrets-loptland.yaml;
      domainname = "christophhollizeck.dev";
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

        templates = {
          "netcup.env" = {
            content = ''
              NETCUP_CUSTOMER_NUMBER=${config.sops.placeholder."netcup/customer_number"}
              NETCUP_API_KEY=${config.sops.placeholder."netcup/api/key"}
              NETCUP_API_PASSWORD=${config.sops.placeholder."netcup/api/password"}
              NETCUP_PROPAGATION_TIMEOUT=1200
            '';
          };
        };

      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          inherit (topLevel.config.flake.meta.users.cholli) email;

          group = lib.mkIf config.services.nginx.enable "nginx";
          reloadServices = lib.mkIf config.services.nginx.enable "nginx.service";

          dnsProvider = "netcup";
          environmentFile = config.sops.templates."netcup.env".path;
        };

        certs."${domainname}" = {
          dnsResolver = "1.1.1.1:53";
          extraDomainNames = [ "*.${domainname}" ];
        };
      };

    };
}
