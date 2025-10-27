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
        nixfmt-rfc-style
        nix-prefetch-git

        nix-index
        nix-output-monitor
      ];

      programs.nh = {
        enable = true;
        package = inputs.nh-flake.packages.${pkgs.system}.nh;
        flake = "/home/${username}/projects/config";
      };

      nix = {
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
            experimental-features = "nix-command flakes";
            http-connections = 50;
            warn-dirty = false;
            log-lines = 50;
            sandbox = "relaxed";
            auto-optimise-store = true;
            trusted-users = users;
            allowed-users = users;
            allowed-uris = "github: https://github.com/ git+https://github.com/ gitlab: https://gitlab.com/ git+https://gitlab.com/";
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
