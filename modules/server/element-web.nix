{
  flake.modules.nixos.element-web =
    { pkgs, ... }:
    let
      matrixDomain = "alwayssleepy.online";
    in
    {
      services.nginx.virtualHosts."chat.${matrixDomain}" = {
        forceSSL = true;
        useACMEHost = matrixDomain;

        locations."= /config.json" = {
          extraConfig = ''
            default_type application/json;
            return 200 '${builtins.toJSON {
              default_server_config = {
                "m.homeserver" = {
                  base_url = "https://matrix.${matrixDomain}";
                  server_name = matrixDomain;
                };
              };
              disable_custom_urls = true;
              disable_guests = true;
              features = {
                feature_group_calls = true;
              };
              element_call = {
                url = "https://call.${matrixDomain}";
                use_exclusively = true;
                brand = "Element Call";
              };
              brand = "Element";
              default_theme = "dark";
            }}';
          '';
        };

        locations."/" = {
          root = "${pkgs.element-web}";
          tryFiles = "$uri /index.html";
          extraConfig = ''
            add_header Cache-Control "no-cache" always;
          '';
        };
      };
    };
}
