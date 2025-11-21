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
      imports = [ inputs.nix-ld.nixosModules.nix-ld ];

      environment.systemPackages = with pkgs; [
        nixfmt-rfc-style
        nix-prefetch-git
        nix-index

        nix-output-monitor

        nix-du
        nix-weather
        nix-index
      ];

      programs.nh = {
        enable = true;
        package = inputs.nh-flake.packages.${pkgs.stdenv.hostPlatform.system}.nh;
        flake = "/home/${username}/projects/config";
      };

      nix = {
        package = pkgs.lix;

        settings =
          let
            users = [
              "root"
              username
            ]
            ++ lib.optional (builtins.hasAttr "native" config.services.gitea-actions-runner) "gitea-runner"
            ++ lib.optional config.services.hydra.enable "hydra hydra-www hydra-evaluator hydra-queue-runner";
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
            allowed-uris = "github: https://github.com/ git+https://github.com/ gitlab: https://gitlab.com/ git+https://gitlab.com/";
            substituters = [
              "https://cache.lix.systems"
              "https://nix-community.cachix.org"
              "https://nixcache.christophhollizeck.dev"
              "https://hyprland.cachix.org"
              "https://nix-gaming.cachix.org"
              "https://nixos-raspberrypi.cachix.org"
            ];
            trusted-public-keys = [
              "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "christophhollizeck.dev:7pPAvm9xqFQB8FDApVNL6Tii1Jsv+Sj/LjEIkdeGhbA="
              "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
              "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
              "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
            ];
          }
          // (lib.optionalAttrs config.programs.direnv.enable {
            keep-outputs = true;
            keep-derivations = true;
          });

        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };
      };
    };
}
