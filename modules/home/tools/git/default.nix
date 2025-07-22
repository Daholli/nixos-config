{
  config,
  lib,
  namespace,
  options,
  ...
}:
with lib.${namespace};
let
  inherit (lib) mkIf types;
  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{
  options.${namespace}.tools.git = {
    enable = mkBoolOpt true "Enable Git (Default true)";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey = mkOpt types.str "ACCFA2DB47795D9E" "The pub key to sign commits with.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {
    systemd.user = {
      services."git-maintenance@" = {
        Unit = {
          Description = "Optimize Git repositories data";
        };
        Service = {
          Type = "oneshot";
          ExecStart = ''"${lib.getExe config.programs.git.package}" --exec-path="${lib.getBin config.programs.git.package}/bin" -c credential.interactive=false -c core.askPass=true for-each-repo --config=maintenance.repo maintenance run --schedule=%i'';
          LockPersonality = "yes";
          MemoryDenyWriteExecute = "yes";
          NoNewPrivileges = "yes";
          RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_VSOCK";
          RestrictNamespaces = "yes";
          RestrictRealtime = "yes";
          RestrictSUIDSGID = "yes";
          SystemCallArchitectures = "native";
          SystemCallFilter = "@system-service";
        };
      };
      timers = {
        "git-maintenance@hourly" = {
          Unit = {
            Description = "Optimize Git repositories data";
          };
          Timer = {
            OnCalendar = "*-*-* *:00:00";
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
        "git-maintenance@daily" = {
          Unit = {
            Description = "Optimize Git repositories data";
          };
          Timer = {
            OnCalendar = "*-*-* 20:00:00";
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
        "git-maintenance@weekly" = {
          Unit = {
            Description = "Optimize Git repositories data";
          };
          Timer = {
            OnCalendar = "Sun *-*-* 20:00:00";
            Persistent = true;
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      };
    };

    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;
      signing = {
        key = cfg.signingKey;
        inherit (cfg) signByDefault;
      };
      extraConfig = {
        core = {
          fsmonitor = true;
        };
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = true;
        };
        push = {
          autoSetupRemote = true;
        };
        rebase = {
          autoStash = true;
        };
        safe = {
          directory = "${user.home}/projects/config";
        };
        maintenance = {
          repo = [
            "${user.home}/projects/nixpkgs"
            "${user.home}/projects/config"
          ];
          strategy = "incremental";
        };
        lfs."https://git.christophhollizeck.dev/Daholli/nixos-config.git/info/lfs".locksverify = true;
      };
    };
  };
}
