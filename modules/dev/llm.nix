{
  flake.modules.homeManager.dev =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      llmPkgs = inputs.llm-agents-nix.packages.${system};

      # ── ponytail ──────────────────────────────────────────────────────────
      ponytail = pkgs.runCommand "ponytail-4.9.0" { } ''
        cp -r ${inputs.ponytail-src} $out
        chmod -R u+w $out
        substituteInPlace $out/hooks/claude-codex-hooks.json \
          --replace-fail '"command": "node ' '"command": "${lib.getExe pkgs.nodejs} '
      '';

      # ── Claude Code statusline ────────────────────────────────────────────
      claude-statusline = pkgs.writeShellScriptBin "claude-statusline" ''
        export PATH=${
          lib.makeBinPath [
            pkgs.jq
            pkgs.git
            pkgs.gawk
            pkgs.coreutils
          ]
        }:$PATH
        ${builtins.readFile ./claude-statusline.sh}
      '';

      # ── MCP server wrappers ───────────────────────────────────────────────
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

      options.local.forgejoMcp.enable = lib.mkEnableOption "the Forgejo MCP server (needs the forgejo/mcp/token sops secret)";

      config = {
        sops.secrets = lib.mkIf config.local.forgejoMcp.enable {
          "forgejo/mcp/token" = {
            sopsFile = ../../secrets/secrets.yaml;
          };
        };

        home.packages = [
          claude-work
          llmPkgs.herdr
        ];

        home.file."${config.programs.claude-code.configDir}/settings.json".force = true;

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
            run ln -sfn "${ponytail}" "${claudeWorkDir}/skills/ponytail"
          '';

        # ── MCP server registry (mcp-servers-nix) ─────────────────────────────
        programs.mcp.enable = true;

        mcp-servers.settings.servers = lib.mkIf config.local.forgejoMcp.enable {
          forgejo = {
            command = lib.getExe forgejo-mcp;
          };
        };

        programs.azure-devops-mcp = {
          enable = true;
          organization = "Qognify";
        };

        # jbcontext itself is enabled per host.
        programs.jbcontext.enableIntellijIntegration = true;

        # ── Claude Code ───────────────────────────────────────────────────────
        programs.claude-code = {
          enable = true;
          package = llmPkgs.claude-code;
          enableMcpIntegration = true;

          plugins = {
            inherit ponytail;
          };

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
            effortLevel = "xhigh";
            remoteControlAtStartup = false;
            permissions.defaultMode = "plan";
            statusLine = {
              type = "command";
              command = lib.getExe claude-statusline;
            };
          };

          # Appended to CLAUDE.md after the instruction block the jbcontext
          # module puts there.
          context = lib.mkIf config.programs.jbcontext.enable ''
            ## Code discovery: Explore agent out, ripgrep still in

            For code discovery in an indexed repo, do NOT use the built-in `Explore`
            agent. It is the nearest competitor to `context-explorer` and silently
            displaces it. Use `context-explorer`, or `jbcontext search` directly.

            This excludes the `Explore` agent only — NOT `rg`/`grep`/`glob`. Those stay
            in normal use, as the second step. Once the semantic pass hands back
            concrete `file:line` pointers, exact search is how you widen from them:
            callers, sibling definitions, every occurrence of a symbol. Semantic search
            finds the entry point; ripgrep confirms and completes it. Skip straight to
            `rg` when the target is genuinely keyword-shaped — a literal string, an
            error message, a flag or config key.

            `Explore` stays fine for sweeps that are not indexed project code: logs,
            build output, nix store sources, or files outside the project. The
            skip-conditions above still apply — this only settles which tool to reach
            for when discovery IS warranted.
          '';
        };

        # ── GitHub Copilot CLI ────────────────────────────────────────────────
        programs.github-copilot-cli = {
          enable = true;
          package = llmPkgs.copilot-cli;
          enableMcpIntegration = true;
        };
      };
    };
}
