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
        name = lib.mkOption {
          type = lib.types.str;
          description = "Display name of the runner shown in Forgejo.";
        };
        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "native:host" ];
          description = "Runner labels used to match jobs (e.g. native:host, aarch64-linux:host).";
        };
        maxJobs = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "Max parallel nix builds (passed via NIX_CONFIG to the runner).";
        };
      };

      config = {
        sops.secrets."forgejo/runner/token" = {
          sopsFile = config.local.forgejoRunner.sopsFile;
        };

        users.groups.secrets-access.members = [ "gitea-runner" ];

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.native = {
            enable = true;
            name = config.local.forgejoRunner.name;
            url = "https://git.christophhollizeck.dev";
            tokenFile = config.sops.secrets."forgejo/runner/token".path;
            labels = config.local.forgejoRunner.labels;
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
            settings = {
              log.level = "info";
              runner = {
                capacity = 1;
                timeout = "3h";
                shutdown_timeout = "5s";
                fetch_timeout = "10s";
                fetch_inteval = "5s";
              };
            };
          };
        };
        systemd.services."gitea-runner-native" = {
          environment.NIX_CONFIG = "max-jobs = ${toString config.local.forgejoRunner.maxJobs}";
          serviceConfig = {
            MemoryHigh = "70%";
            OOMScoreAdjust = 500;
          };
        };
      };
    };
}
