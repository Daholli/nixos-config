{
  flake.modules.homeManager.dev =
    {
      config,
      osConfig,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      isYggdrasil = osConfig.networking.hostName == "yggdrasil";
      system = pkgs.stdenv.hostPlatform.system;
      llmPkgs = inputs.llm-agents-nix.packages.${system};

      # ── jbcontext ─────────────────────────────────────────────────────────
      # Not yet in llm-agents.nix; built from the upstream prebuilt binary
      # pinned via flake.lock (inputs.jbcontext-src).
      jbcontext = pkgs.stdenv.mkDerivation {
        pname = "jbcontext";
        version = "0.9.4.313";

        src = inputs.jbcontext-src;

        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.zlib ];

        dontUnpack = true;
        dontBuild = true;

        installPhase = ''
          install -Dm755 $src $out/bin/jbcontext
        '';

        meta = {
          description = "JetBrains Context CLI — code indexing and semantic search for AI agents";
          homepage = "https://www.jetbrains.com/ai/";
          license = lib.licenses.unfree;
          platforms = [ "x86_64-linux" ];
          mainProgram = "jbcontext";
        };
      };

      jbcontextBin = lib.getExe jbcontext;

      # ── MCP server wrappers ───────────────────────────────────────────────
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
      imports = [
        inputs.mcp-servers-nix.homeManagerModules.default
      ];

      sops.secrets = lib.mkIf isYggdrasil {
        "forgejo/mcp/token" = {
          sopsFile = ../../secrets/secrets.yaml;
        };
      };

      home.packages = [
        claude-work
      ]
      ++ lib.optionals isYggdrasil [ jbcontext ];

      # ── MCP server registry (mcp-servers-nix) ─────────────────────────────
      # All servers defined here are automatically wired into any program with
      # enableMcpIntegration = true (e.g. programs.claude-code below).
      programs.mcp.enable = true;

      mcp-servers.settings.servers = {
        azure-devops = {
          command = lib.getExe azure-devops-mcp;
          args = [ "Qognify" ];
        };
      }
      // lib.optionalAttrs isYggdrasil {
        forgejo = {
          command = lib.getExe forgejo-mcp;
        };
        jbcontext = {
          command = jbcontextBin;
          args = [ "mcp" ];
        };
      };

      # ── Claude Code ───────────────────────────────────────────────────────
      programs.claude-code = {
        enable = true;
        package = llmPkgs.claude-code;
        enableMcpIntegration = true;

        settings = {
          theme = "auto";
          autoCompactEnabled = true;
        }
        // lib.optionalAttrs isYggdrasil {
          hooks = {
            SessionStart = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} index --silent";
                    async = true;
                  }
                ];
              }
            ];
            SessionEnd = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} index --silent";
                    async = true;
                  }
                ];
              }
            ];
            PreToolUse = [
              {
                matcher = "Bash|Grep";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} hook pre-tool-use";
                  }
                ];
              }
            ];
            UserPromptSubmit = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} hook user-prompt-submit";
                  }
                ];
              }
            ];
          };
        };
      };

      # ── GitHub Copilot CLI ────────────────────────────────────────────────
      programs.github-copilot-cli = {
        enable = true;
        package = llmPkgs.copilot-cli;
        enableMcpIntegration = true;
      };

      # ── Junie ─────────────────────────────────────────────────────────────
      programs.junie = {
        enable = true;
        package = llmPkgs.junie;
        enableMcpIntegration = true;

        settings = lib.optionalAttrs isYggdrasil {
          hooks = {
            SessionStart = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} index --silent";
                    async = true;
                  }
                ];
              }
            ];
            SessionEnd = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} index --silent";
                    async = true;
                  }
                ];
              }
            ];
            PreToolUse = [
              {
                matcher = "Bash|Grep";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} hook pre-tool-use";
                  }
                ];
              }
            ];
            UserPromptSubmit = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "${jbcontextBin} hook user-prompt-submit";
                  }
                ];
              }
            ];
          };
        };
      };
    };
}
