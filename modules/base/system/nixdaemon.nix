{
  flake.modules.nixos.base =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      username = "cholli";
    in
    {
      # imports = [ inputs.nix-ld.nixosModules.nix-ld ];

      environment.systemPackages = with pkgs; [
        nixfmt
        nix-prefetch-git
        nix-index

        nix-output-monitor

        nix-du
        nix-weather
        nix-index

        inputs.nix-auth.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      programs.nh = {
        enable = true;
        package = inputs.nh-flake.packages.${pkgs.stdenv.hostPlatform.system}.nh;
        flake = "/home/${username}/projects/config";

        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 5";
      };

      sops = {
        secrets."github/pat" = {
          sopsFile = ../../../secrets/secrets.yaml;
        };
        templates."access_tokens.conf" = {
          content = ''
            access-tokens = github.com=${config.sops.placeholder."github/pat"}
          '';
          owner = "root";
          group = "secrets-access";
          mode = "0440";
        };
      };

      nix = {
        package = pkgs.lix;

        extraOptions = "!include ${config.sops.templates."access_tokens.conf".path}";

        settings =
          let
            users = [
              "root"
              username
            ]
            ++ lib.optional (builtins.hasAttr "native" config.services.gitea-actions-runner.instances) "gitea-runner"
            ++ lib.optional config.services.hydra.enable "hydra hydra-www hydra-evaluator";
          in
          {

            nix-path = "nixpkgs=flake:nixpkgs";
            experimental-features = "nix-command flakes";
            http-connections = 50;
            warn-dirty = false;
            log-lines = 50;
            sandbox = "relaxed";
            auto-optimise-store = true;
            trusted-users = users;
            allowed-users = users;
            allowed-uris = "github: https://github.com/ git+https://github.com/ gitlab: https://gitlab.com/ git+https://gitlab.com/ git+https://codeberg.org/";
            substituters = [
              "https://cache.lix.systems"
              "https://nix-community.cachix.org"
              "https://helix.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
              "https://nixcache.christophhollizeck.dev"

              "https://nix-cache.tokidoki.dev/tokidoki"
            ];
            trusted-public-keys = [
              "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
              "christophhollizeck.dev:7pPAvm9xqFQB8FDApVNL6Tii1Jsv+Sj/LjEIkdeGhbA="

              "tokidoki:MD4VWt3kK8Fmz3jkiGoNRJIW31/QAm7l1Dcgz2Xa4hk="
            ];
          }
          // (lib.optionalAttrs config.programs.direnv.enable {
            keep-outputs = true;
            keep-derivations = true;
          });
      };
    };
}
