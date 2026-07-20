{
  flake.modules.homeManager.dev =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      isYggdrasil = osConfig.networking.hostName == "yggdrasil";
      azure-devops-mcp = pkgs.writeShellApplication {
        name = "azure-devops-mcp";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec npx -y @azure-devops/mcp "$@"
        '';
      };

      forgejo-mcp = pkgs.writeShellApplication {
        name = "forgejo-mcp";
        runtimeInputs = [ pkgs.forgejo-mcp ];
        text = ''
          exec forgejo-mcp \
            -url https://git.christophhollizeck.dev \
            -token "$(cat ${config.sops.secrets."forgejo/mcp/token".path})" \
            "$@"
        '';
      };

      # Runs Claude Code against a separate config dir (~/.claude-work) so it
      # can hold its own login session/credentials independent of `claude`.
      claude-work = pkgs.writeShellApplication {
        name = "claude-work";
        runtimeInputs = [ config.programs.claude-code.finalPackage ];
        text = ''
          export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
          exec claude "$@"
        '';
      };
    in
    {
      sops.secrets = lib.mkIf isYggdrasil {
        "forgejo/mcp/token" = {
          sopsFile = ../../secrets/secrets.yaml;
        };
      };

      home.packages = [ claude-work ];

      programs.claude-code = {
        enable = true;

        mcpServers = {
          azure-devops = {
            type = "stdio";
            command = lib.getExe azure-devops-mcp;
            args = [ "Qognify" ];
          };
        }
        // lib.optionalAttrs isYggdrasil {
          forgejo = {
            type = "stdio";
            command = lib.getExe forgejo-mcp;
          };
        };
      };
    };
}
