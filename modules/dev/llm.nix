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
        llmPkgs.herdr
      ]
      ++ lib.optionals isYggdrasil [ jbcontext ];

      home.activation.claudeSettingsMutable = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        let
          settingsFile = "${config.programs.claude-code.configDir}/settings.json";
        in
        ''
          if [ -L "${settingsFile}" ]; then
            run cp --remove-destination "$(readlink -f "${settingsFile}")" "${settingsFile}"
            run chmod u+w "${settingsFile}"
          fi
        ''
      );

      home.activation.claudeWorkConfig =
        let
          claudeConfigDir = config.programs.claude-code.configDir;
          claudeWorkDir = "${config.home.homeDirectory}/.claude-work";
        in
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run mkdir -p "${claudeWorkDir}/skills"
          run ln -sfn "${claudeConfigDir}/settings.json" "${claudeWorkDir}/settings.json"
          if [ -e "${claudeConfigDir}/skills/claude-code-home-manager" ]; then
            run ln -sfn "${claudeConfigDir}/skills/claude-code-home-manager" \
              "${claudeWorkDir}/skills/claude-code-home-manager"
          fi
        '';

      # ── MCP server registry (mcp-servers-nix) ─────────────────────────────
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

        # Deliberately just "rust-analyzer" (not a nix store path): this
        # picks up whatever rust-analyzer a project's devenv/toolchain puts
        # on PATH, rather than pinning a specific nixpkgs build.
        lspServers = {
          rust = {
            command = "rust-analyzer";
            args = [ ];
            extensionToLanguage = {
              ".rs" = "rust";
            };
          };
        };

        settings = {
          theme = "auto";
          autoCompactEnabled = true;
          model = "opus";
          effortLevel = "medium";
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
