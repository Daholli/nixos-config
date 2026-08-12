{
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.programs.junie;
    in
    {
      options.programs.junie = {
        enable = lib.mkEnableOption "Junie CLI";

        package = lib.mkOption {
          type = lib.types.package;
          description = "The Junie CLI package to use.";
        };

        enableMcpIntegration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable MCP integration for Junie.";
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Settings for Junie CLI (config.json).";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        home.file.".junie/config.json" = lib.mkIf (cfg.settings != { }) {
          text = builtins.toJSON cfg.settings;
        };

        home.file.".junie/mcp/mcp.json" = lib.mkIf cfg.enableMcpIntegration {
          text = builtins.toJSON {
            mcpServers = lib.mapAttrs (
              _name: value:
              (lib.optionalAttrs (value ? command) {
                inherit (value) command;
                args = value.args or [ ];
                env = value.env or { };
              })
              // (lib.optionalAttrs (value ? url) {
                inherit (value) url;
                headers = value.headers or { };
              })
            ) config.mcp-servers.settings.servers;
          };
        };
      };
    };
}
