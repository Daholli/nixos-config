{
  flake.modules.nixos.forgejo-runner =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    {
      options.local.forgejoRunner = {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to the sops secrets file containing forgejo/runner/token.";
        };
        uuid = lib.mkOption {
          type = lib.types.str;
          description = "UUID of the runner as registered on the Forgejo instance.";
        };
        name = lib.mkOption {
          type = lib.types.str;
          description = "Display name of the runner shown in Forgejo.";
        };
        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra runner labels in addition to native:host and <system>:host.";
        };
        maxJobs = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "Max parallel nix builds (passed via NIX_CONFIG to the runner).";
        };
      };

      config =
        let
          effectiveLabels = [
            "native:host"
            "${pkgs.stdenv.hostPlatform.system}:host"
          ]
          ++ config.local.forgejoRunner.labels;
        in
        {
          sops.secrets."forgejo/runner/token" = {
            sopsFile = config.local.forgejoRunner.sopsFile;
          };

          sops.templates."forgejo-runner.yaml" = {
            group = "secrets-access";
            mode = "0440";
            content = ''
              log:
                level: info
              runner:
                capacity: 1
                timeout: 24h
                shutdown_timeout: 5s
                fetch_timeout: 10s
                fetch_interval: 5s
                labels: ${builtins.toJSON effectiveLabels}
              server:
                connections:
                  forgejo:
                    url: https://git.christophhollizeck.dev/
                    uuid: ${config.local.forgejoRunner.uuid}
                    token: ${config.sops.placeholder."forgejo/runner/token"}
            '';
          };

          services.gitea-actions-runner = {
            package = pkgs.forgejo-runner;
            instances.native = {
              enable = true;
              name = config.local.forgejoRunner.name;
              url = "https://git.christophhollizeck.dev";
              tokenFile = config.sops.secrets."forgejo/runner/token".path;
              labels = effectiveLabels;
              hostPackages = with pkgs; [
                bash
                coreutils
                curl
                gawk
                gitMinimal
                gnused
                nodejs
                wget
                lix
                inputs.omnix.packages.${pkgs.stdenv.hostPlatform.system}.default
              ];
            };
          };

          systemd.services."gitea-runner-native" = {
            environment.NIX_CONFIG = "max-jobs = ${toString config.local.forgejoRunner.maxJobs}";
            serviceConfig = {
              MemoryHigh = "70%";
              OOMScoreAdjust = 500;
              SupplementaryGroups = [ "secrets-access" ];
              ExecStart = lib.mkForce "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${
                config.sops.templates."forgejo-runner.yaml".path
              }";
              ExecStartPre = lib.mkForce "";
              PrivateTmp = false;
            };
          };
        };
    };
}
