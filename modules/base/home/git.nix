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
        osConfig,
        pkgs,
        ...
      }:
      let
        username = topLevel.config.flake.meta.users.cholli.username;
      in
      {
        home.packages = [
          pkgs.git-credential-manager
        ];

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
            credential = {
              helper = "manager";
              credentialStore = "secretservice";
              "https://dev.azure.com".useHttpPath = true;
            };
            core = {
              fsmonitor = true;
              editor = "hx";
            };
            commit.verbose = true;
            init.defaultBranch = "main";
            pull.rebase = true;
            fetch = {
              prune = true;
              pruneTags = true;
            };
            push.autoSetupRemote = true;
            rebase = {
              autoStash = true;
              autoSquash = true;
            };
            merge.conflictstyle = "zdiff3";
            safe.directory = "/home/${username}/projects/config";
            submodules.recurse = true;
            help.autocorrect = "prompt";
            maintenance = {
              repo = [
                "/home/${username}/projects/NixOS/nixpkgs"
                "/home/${username}/projects/config"
              ];
              strategy = "incremental";
            };
            lfs."https://git.christophhollizeck.dev/Daholli/nixos-config.git/info/lfs".locksverify = true;
          };
        };

        systemd.user = lib.mkIf (osConfig.networking.hostName == "yggdrasil") {
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
