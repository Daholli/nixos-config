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
      cfg = config.programs.jbcontext;
      jbcontextBin = lib.getExe cfg.package;

      jbcontext = pkgs.stdenv.mkDerivation {
        pname = "jbcontext";
        version = "0.9.12.803";

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

      # The skills, subagent and instruction blocks `jbcontext setup-agent`
      # would write, generated from the pinned binary so they follow every
      # version bump. setup-agent falls back to its bundled prompts offline,
      # so this works inside the build sandbox.
      agentFiles =
        pkgs.runCommand "jbcontext-agent-files-${cfg.package.version}"
          {
            nativeBuildInputs = [ cfg.package ];
          }
          ''
            export HOME=$TMPDIR
            mkdir -p $out
            cd $out
            jbcontext setup-agent --non-interactive --scope=project --agent=claude \
              --skills --subagents --instructions
            jbcontext setup-agent --non-interactive --scope=project --agent=intellij \
              --skills --instructions

            # home-manager serves MCP servers through its generated `hm` plugin,
            # so Claude Code names the tool mcp__plugin_hm_<server>__<tool>.
            substituteInPlace .claude/agents/context-explorer.md \
              --replace-fail mcp__jbcontext__code_search mcp__plugin_hm_jbcontext__code_search
          '';

      indexHook = [
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
    in
    {
      options.programs.jbcontext = {
        enable = lib.mkEnableOption "JetBrains Context CLI";

        package = lib.mkOption {
          type = lib.types.package;
          default = jbcontext;
          description = "The JetBrains Context CLI package to use.";
        };

        enableIntellijIntegration = lib.mkEnableOption "the JetBrains Context skill and instructions for IntelliJ ACP agents";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        mcp-servers.settings.servers.jbcontext = {
          command = jbcontextBin;
          args = [ "mcp" ];
        };

        # Mirrors `jbcontext setup-agent --auto`, which no longer includes the
        # tool-watching PreToolUse/UserPromptSubmit hooks.
        programs.claude-code = {
          skills.context-search = "${agentFiles}/.claude/skills/context-search";
          agents.context-explorer = "${agentFiles}/.claude/agents/context-explorer.md";
          context = lib.mkBefore (builtins.readFile "${agentFiles}/CLAUDE.md" + "\n");
          settings.hooks = {
            SessionStart = indexHook;
            SessionEnd = indexHook;
          };
        };

        home.file = lib.mkIf cfg.enableIntellijIntegration {
          ".ai/AGENTS.md".source = "${agentFiles}/AGENTS.md";
          ".ai/skills/context-search/SKILL.md".source = "${agentFiles}/.ai/skills/context-search/SKILL.md";
        };
      };
    };
}
