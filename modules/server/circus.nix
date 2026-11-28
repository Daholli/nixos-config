topLevel: {
  flake.modules.nixos.circus =
    {
      config,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.local.circus;
      secret = name: config.sops.secrets."circus/${name}".path;
    in
    {
      imports = [ inputs.circus.nixosModules.circus ];

      options.local.circus = {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops file holding the circus/* secrets.";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          description = "Public hostname the dashboard and webhooks are served on.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 3010;
        };
        rpcPort = lib.mkOption {
          type = lib.types.port;
          default = 8443;
          description = "Agent RPC port, only opened on tailscale0.";
        };
        localSystems = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "x86_64-linux" ];
        };
        workers = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
        };
        joinTokens = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Agent join token name -> SHA-256 hex digest of the raw token.";
        };
        projects = lib.mkOption {
          description = "Repositories to build. Forgejo ones need a repo webhook using circus/webhook-secret.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (project: {
              options = {
                forge = lib.mkOption {
                  type = lib.types.enum [
                    "forgejo"
                    "none"
                  ];
                  default = "forgejo";
                  description = "Forge sending push webhooks; `none` relies on polling only.";
                };
                repo = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  example = "Daholli/nixos-config";
                  description = "owner/name on the local Forgejo; derives `url`.";
                };
                url = lib.mkOption {
                  type = lib.types.str;
                  example = "https://dev.azure.com/org/project/_git/repo";
                  description = "Git clone URL.";
                };
                branch = lib.mkOption {
                  type = lib.types.str;
                  default = "main";
                };
                jobsets = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "packages"
                    "checks"
                  ];
                  description = "Flake output attributes to build, one jobset each.";
                };
              };
              config.url = lib.mkIf (project.config.repo != null) (
                lib.mkDefault "${config.services.forgejo.settings.server.ROOT_URL}/${project.config.repo}.git"
              );
            })
          );
        };
      };

      config = {
        sops.secrets =
          lib.genAttrs
            [
              "circus/forgejo-token"
              "circus/webhook-secret"
              "circus/encryption-key"
              "circus/admin-password"
            ]
            (_: {
              inherit (cfg) sopsFile;
              restartUnits = [
                "circus-server.service"
                "circus-evaluator.service"
                "circus-queue-runner.service"
              ];
            });

        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.rpcPort ];

        services.circus = {
          enable = true;
          server.enable = true;
          evaluator.enable = true;
          queueRunner.enable = true;

          settings = {
            server = {
              host = "127.0.0.1";
              inherit (cfg) port;
              force_secure_cookies = true;
              webhook_secret_encryption_key_file = secret "encryption-key";
            };

            # outputs reach attic through attic watch-store instead
            cache.enabled = false;

            evaluator = {
              systems = [
                "x86_64-linux"
                "aarch64-linux"
              ];
              poll_interval = 300;
            };

            queue_runner = {
              inherit (cfg) workers;
              local_systems = cfg.localSystems;
              rpc = {
                bind = "0.0.0.0:${toString cfg.rpcPort}";
                # the port is only reachable over tailscale, which already encrypts
                allow_plaintext = true;
                join_tokens = lib.mapAttrsToList (name: token_hash: { inherit name token_hash; }) cfg.joinTokens;
              };
            };

            notifications = {
              gitea_url = config.services.forgejo.settings.server.ROOT_URL;
              gitea_token_file = secret "forgejo-token";
            };

            declarative = {
              projects = lib.mapAttrsToList (name: project: {
                inherit name;
                repository_url = project.url;
                cache_enabled = false;
                webhooks = lib.optional (project.forge == "forgejo") {
                  forge_type = "forgejo";
                  secret_file = secret "webhook-secret";
                };
                jobsets = map (expr: {
                  name = expr;
                  nix_expression = expr;
                  inherit (project) branch;
                  only_build_latest = true;
                }) project.jobsets;
              }) cfg.projects;
              users = [
                {
                  username = "cholli";
                  inherit (topLevel.config.flake.meta.users.cholli) email;
                  role = "admin";
                  password_file = secret "admin-password";
                }
              ];
              api_keys = [ ];
            };
          };
        };
      };
    };
}
