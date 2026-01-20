{
  flake.modules.nixos.hydra =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      httpPort = 2000;

      generateHostEntry = machine: ''
        Host ${machine.hostName}
          IdentitiesOnly yes
          IdentityFile ${machine.sshKey}
          User remotebuild
      '';

      filteredMachines = lib.filter (machine: machine.hostName != "localhost") config.nix.buildMachines;
      remotebuild-ssh-config = pkgs.writeTextFile {
        name = "remotebuild-ssh-config";
        text = lib.concatMapStringsSep "\n" generateHostEntry filteredMachines;
      };
    in
    {
      services.nix-serve = {
        enable = true;
        secretKeyFile = "/var/cache-priv-key.pem";
      };

      services.hydra = {
        enable = true;
        package = inputs.hydra-ci.packages.${pkgs.stdenv.system}.hydra;

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
