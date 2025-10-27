topLevel: {
  flake.modules = {
    nixos.base =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          git
        ];

      };

    homeManager.cholli =
      {
        config,
        lib,
        ...
      }:
      let
        username = topLevel.config.flake.meta.users.cholli.username;
      in
      {
        programs.git = {
          enable = true;
          lfs.enable = true;
          signing = {
            key = topLevel.config.flake.meta.users.cholli.key;
            signByDefault = true;
          };
          ignores = [
            ".direnv/"
            ".devenv/"
            "result"
          ];

          settings = {
            user = {
              name = topLevel.config.flake.meta.users.cholli.name;
              email = topLevel.config.flake.meta.users.cholli.email;
            };
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
              directory = "/home/${username}/projects/config";
            };
            maintenance = {
              repo = [
                "home/${username}/projects/nixpkgs"
                "home/${username}/projects/config"
              ];
              strategy = "incremental";
            };
            lfs."https://git.christophhollizeck.dev/Daholli/nixos-config.git/info/lfs".locksverify = true;
          };
        };

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
      };
  };
}
