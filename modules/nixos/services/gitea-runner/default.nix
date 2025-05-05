{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
with lib.${namespace};
let
  cfg = config.${namespace}.services.gitea-runner;
  inherit (lib) mkIf mkOption mkEnableOption;
  inherit (lib.types)
    attrsOf
    package
    path
    submodule
    str
    ;
in
{
  options.${namespace}.services.gitea-runner = {
    enable = mkEnableOption "Enable gitea/forgejo runner";
    git-url = mkOption {
      type = str;
      default = "https://git.christophhollizeck.dev";
    };
    sopsFile = mkOption {
      type = path;
      default = lib.snowfall.fs.get-file "secrets/secrets.yaml";
      description = "SecretFile";
    };
    runner-package = mkOption {
      type = package;
      default = pkgs.forgejo-actions-runner;
      description = "Which runner to use Gitea/Forgjo";
    };
    ## taken from nixos/modules/services/continuous-integration/gitea-actions-runner.nix
    runner-instances = mkOption {
      default = { };
      description = ''
        Gitea Actions Runner instances.
      '';
      type = attrsOf (submodule {
        options = {
          enable = mkEnableOption "Gitea Actions Runner instance";
          name = mkOption {
            type = str;
            example = literalExpression "config.networking.hostName";
            description = ''
              The name identifying the runner instance towards the Gitea/Forgejo instance.
            '';
          };
          url = mkOption {
            type = str;
            example = "https://forge.example.com";
            description = ''
              Base URL of your Gitea/Forgejo instance.
            '';
          };
          tokenFile = mkOption {
            type = nullOr (either str path);
            default = null;
            description = ''
              Path to an environment file, containing the `TOKEN` environment
              variable, that holds a token to register at the configured
              Gitea/Forgejo instance.
            '';
          };
          labels = mkOption {
            type = listOf str;
            example = literalExpression ''
              [
                # provide a debian base with nodejs for actions
                "debian-latest:docker://node:18-bullseye"
                # fake the ubuntu name, because node provides no ubuntu builds
                "ubuntu-latest:docker://node:18-bullseye"
                # provide native execution on the host
                #"native:host"
              ]
            '';
            description = ''
              Labels used to map jobs to their runtime environment. Changing these
              labels currently requires a new registration token.

              Many common actions require bash, git and nodejs, as well as a filesystem
              that follows the filesystem hierarchy standard.
            '';
          };
          settings = mkOption {
            description = ''
              Configuration for `act_runner daemon`.
              See https://gitea.com/gitea/act_runner/src/branch/main/internal/pkg/config/config.example.yaml for an example configuration
            '';

            type = types.submodule {
              freeformType = settingsFormat.type;
            };

            default = { };
          };

          hostPackages = mkOption {
            type = listOf package;
            default = with pkgs; [
              bash
              coreutils
              curl
              gawk
              gitMinimal
              gnused
              nodejs
              wget
            ];
            defaultText = literalExpression ''
              with pkgs; [
                bash
                coreutils
                curl
                gawk
                gitMinimal
                gnused
                nodejs
                wget
              ]
            '';
            description = ''
              List of packages, that are available to actions, when the runner is configured
              with a host execution label.
            '';
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "forgejo/runner/token" = {
          inherit (cfg) sopsFile;
        };
      };
    };

    services.gitea-actions-runner = {
      package = cfg.runner-package;
      instances = {
        native = {
          enable = true;
          name = "monolith";
          url = cfg.git-url;
          tokenFile = config.sops.secrets."forgejo/runner/token".path;
          labels = [
            "native:host"
          ];
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
      } // cfg.runner-instances;
    };

  };
}
