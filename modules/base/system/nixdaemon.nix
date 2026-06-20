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
      environment.systemPackages = with pkgs; [
        nixfmt
        nix-prefetch-git
        nix-index

        nix-output-monitor

        nix-du
        nix-weather
        nix-index

        nix-update
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
        secrets."nix/signing-key" = {
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
            ++ lib.optional (builtins.hasAttr "native" config.services.gitea-actions-runner.instances) "gitea-runner";
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
            allowed-uris = "github: https://github.com/ git+https://github.com/ gitlab: https://gitlab.com/ git+https://gitlab.com/ git+https://codeberg.org/ git+https://git.christophhollizeck.dev/";
            substituters = [
              "https://cache.lix.systems"
              "https://nix-community.cachix.org"
              "https://helix.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
              "https://cholli.cachix.org"
            ];
            secret-key-files = [ config.sops.secrets."nix/signing-key".path ];
            trusted-public-keys = [
              "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
              "cholli.cachix.org-1:1nQ9JUO/1sHK7wm5obDgR/DNndPUsApBshQnEPIoMfI="
              # generated with: nix key generate-secret --key-name cholli-local-1
              "cholli-local-1:v/wzL3lqs/CBDwSohhoRHlTJbqsf67DZDqfRDcp0cdA="
            ];
            fallback = true;
          };
      };
    };
}
