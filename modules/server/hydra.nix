{
  flake.modules.nixos.hydra =
    { config, pkgs, ... }:
    let
      httpPort = 2000;

      remotebuild-ssh-config = pkgs.writeTextFile {
        name = "remotebuild-ssh-config";
        text = ''
          Host nixberry
            IdentitiesOnly yes
            IdentityFile ${config.sops.secrets."hydra/remotebuild/private-key".path}
            User remotebuild
        '';
      };
    in
    {
      services.nix-serve = {
        enable = true;
        secretKeyFile = "/var/cache-priv-key.pem";
      };

      services.hydra = {
        enable = true;
        hydraURL = "http://localhost:${toString httpPort}";
        port = httpPort;
        notificationSender = "hydra@localhost";
        useSubstitutes = true;
      };

      systemd =
        let
          user = "hydra-queue-runner";
        in
        {
          tmpfiles.rules = [
            "d ${config.users.users.${user}.home}/.ssh 0700 ${user} ${user} -"
          ];

          services.hydra-queue-runner = {

            serviceConfig.ExecStartPre =
              let
                targetFile = "${config.users.users.${user}.home}/.ssh/config";
              in
              ''
                ${pkgs.coreutils}/bin/ln -sf ${remotebuild-ssh-config} ${targetFile}
                ${pkgs.coreutils}/bin/chown ${user}:${user} ${targetFile} 
              '';
          };
        };

    };
}
