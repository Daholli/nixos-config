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

        container = lib.mkOption {
          default = null;
          description = "A second runner instance that executes jobs in ephemeral podman containers instead of on the host.";
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                sopsFile = lib.mkOption {
                  type = lib.types.path;
                  description = "Path to the sops secrets file containing forgejo/runner/container/token.";
                };
                uuid = lib.mkOption {
                  type = lib.types.str;
                  description = "UUID of the container runner as registered on the Forgejo instance.";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name of the container runner shown in Forgejo.";
                };
                labels = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ "container:docker://node:20-bookworm" ];
                  description = "Runner labels, each mapping a `runs-on` value to a docker image.";
                };
              };
            }
          );
        };
      };

      config =
        let
          effectiveLabels = [
            "native:host"
            "${pkgs.stdenv.hostPlatform.system}:host"
          ]
          ++ config.local.forgejoRunner.labels;
          containerCfg = config.local.forgejoRunner.container;
        in
        lib.mkMerge [
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
                  cachix
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
          }
          (lib.mkIf (containerCfg != null) {
            virtualisation.podman.enable = true;

            sops.secrets."forgejo/runner/container/token" = {
              inherit (containerCfg) sopsFile;
            };

            sops.templates."forgejo-runner-container.yaml" = {
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
                  labels: ${builtins.toJSON containerCfg.labels}
                server:
                  connections:
                    forgejo:
                      url: https://git.christophhollizeck.dev/
                      uuid: ${containerCfg.uuid}
                      token: ${config.sops.placeholder."forgejo/runner/container/token"}
              '';
            };

            services.gitea-actions-runner.instances.container = {
              enable = true;
              inherit (containerCfg) name;
              url = "https://git.christophhollizeck.dev";
              tokenFile = config.sops.secrets."forgejo/runner/container/token".path;
              inherit (containerCfg) labels;
            };

            systemd.services."gitea-runner-container" = {
              serviceConfig = {
                MemoryHigh = "70%";
                OOMScoreAdjust = 500;
                SupplementaryGroups = [ "secrets-access" ];
                ExecStart = lib.mkForce "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config ${
                  config.sops.templates."forgejo-runner-container.yaml".path
                }";
                ExecStartPre = lib.mkForce "";
                PrivateTmp = false;
              };
            };
          })
        ];
    };
}
