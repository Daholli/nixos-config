{ withSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.azure-devops-mcp = pkgs.callPackage (
        {
          lib,
          buildNpmPackage,
          fetchFromGitHub,
          pkg-config,
          python3,
          libsecret,
        }:
        buildNpmPackage (finalAttrs: {
          pname = "azure-devops-mcp";
          version = "2.10.0";

          src = fetchFromGitHub {
            owner = "microsoft";
            repo = "azure-devops-mcp";
            tag = "v${finalAttrs.version}";
            hash = "sha256-So/zsCt8uLAOjdk0OdgB6ENe9x2mmMy8YM4V/xlG+6c=";
          };

          npmDepsHash = "sha256-ZWWiPIVovkSDJNhih/neXuUlDJcMK21xk1P4j6uGNYY=";

          # keytar (via @azure/msal-node-extensions since 2.10.0) can't fetch its
          # prebuilt binary in the sandbox, so node-gyp builds it against libsecret.
          nativeBuildInputs = [
            pkg-config
            python3
          ];
          buildInputs = [ libsecret ];
          makeCacheWritable = true;

          meta = {
            description = "MCP server for interacting with Azure DevOps";
            homepage = "https://github.com/microsoft/azure-devops-mcp";
            license = lib.licenses.mit;
            mainProgram = "mcp-server-azuredevops";
          };
        })
      ) { };
    };

  flake.modules.homeManager.dev =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.azure-devops-mcp;
    in
    {
      options.programs.azure-devops-mcp = {
        enable = lib.mkEnableOption "the Azure DevOps MCP server";

        package = lib.mkOption {
          type = lib.types.package;
          default = withSystem pkgs.stdenv.hostPlatform.system (
            { config, ... }: config.packages.azure-devops-mcp
          );
          description = "The Azure DevOps MCP server package to use.";
        };

        organization = lib.mkOption {
          type = lib.types.str;
          description = "Azure DevOps organization the server connects to.";
        };
      };

      config = lib.mkIf cfg.enable {
        mcp-servers.settings.servers.azure-devops = {
          command = lib.getExe cfg.package;
          args = [ cfg.organization ];
        };
      };
    };
}
