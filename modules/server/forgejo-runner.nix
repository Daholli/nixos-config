{
  flake.modules.nixos.forgejo-runner =
    { config, pkgs, ... }:
    let
      sopsFile = ../../secrets/secrets-loptland.yaml;
    in
    {
      sops = {
        secrets = {
          "forgejo/runner/token" = {
            inherit sopsFile;
          };
        };
      };

      services.gitea-actions-runner = {
        package = pkgs.forgejo-actions-runner;
        instances = {
          native = {
            enable = true;
            name = "monolith";
            url = "https://git.christophhollizeck.dev";
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
        };
      };
    };
}
