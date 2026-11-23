{
  flake.modules.nixos.sable-web =
    { pkgs, ... }:
    let
      matrixDomain = "alwayssleepy.online";
      sable = pkgs.sable.override {
        conf = {
          homeserverList = [ matrixDomain ];
          defaultHomeserver = 0;
          allowCustomHomeservers = true;
          elementCallUrl = "https://call.${matrixDomain}";
          featuredCommunities = {
            openAsDefault = false;
            spaces = [ ];
            rooms = [ ];
            servers = [ ];
          };
        };
      };
    in
    {
      services.nginx.virtualHosts."chat.${matrixDomain}" = {
        forceSSL = true;
        useACMEHost = matrixDomain;

        locations."/" = {
          root = "${sable}";
          tryFiles = "$uri /index.html";
          extraConfig = ''
            add_header Cache-Control "no-cache" always;
          '';
        };
      };
    };
}
