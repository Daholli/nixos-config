{
  flake.modules.nixos.circus-agent =
    {
      config,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.local.circusAgent;
    in
    {
      imports = [ inputs.circus.nixosModules.circus-agent ];

      options.local.circusAgent = {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops file holding circus/join-token.";
        };
        runnerUrl = lib.mkOption {
          type = lib.types.str;
          example = "circus://100.64.0.1:8443";
        };
        maxJobs = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
        };
      };

      config = {
        sops.secrets."circus/join-token" = { inherit (cfg) sopsFile; };

        services.circus-agent = {
          enable = true;
          joinTokenFile = config.sops.secrets."circus/join-token".path;
          settings.agent = {
            name = config.networking.hostName;
            runner_url = cfg.runnerUrl;
            max_jobs = cfg.maxJobs;
          };
        };
      };
    };
}
