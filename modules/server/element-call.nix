topLevel: {
  flake.modules.nixos.element-call =
    { config, lib, pkgs, ... }:
    let
      matrixDomain = "alwayssleepy.online";
      livekitPort = 7880;
      livekitRtcPortStart = 50000;
      livekitRtcPortEnd = 50200;
      lkJwtPort = 8089;
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      sops.secrets."matrix/livekit/keyFile" = {
        inherit sopsFile;
        # livekit and lk-jwt-service both read this file
        mode = "0440";
        group = "livekit-secrets";
      };

      users.groups.livekit-secrets = { };

      # LiveKit SFU media server
      services.livekit = {
        enable = true;
        openFirewall = true;
        keyFile = config.sops.secrets."matrix/livekit/keyFile".path;

        settings = {
          port = livekitPort;
          rtc = {
            port_range_start = livekitRtcPortStart;
            port_range_end = livekitRtcPortEnd;
          };
        };
      };

      # lk-jwt-service: bridges Matrix OpenID tokens to LiveKit JWTs
      services.lk-jwt-service = {
        enable = true;
        livekitUrl = "wss://call.${matrixDomain}/livekit/sfu";
        keyFile = config.sops.secrets."matrix/livekit/keyFile".path;
        port = lkJwtPort;
      };

      # Allow lk-jwt-service (DynamicUser) to read the secrets file
      systemd.services.lk-jwt-service.serviceConfig.SupplementaryGroups = [ "livekit-secrets" ];
    };
}
