{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.fish;
in {
  options.wyrdgard.apps.cli-apps.fish = with types; {
    enable = mkBoolOpt true "Whether or not to enable the fish shell";
  };

  config =
    mkIf cfg.enable {
      home.packages = with pkgs.fishPlugins; [
        forgit
        sponge
      ];

      programs = {
        fish = {
          enable = true;
          shellInit = "
	zoxide init fish | source
	starship init fish | source
	direnv hook fish | source
	source ~/.config/op/plugins.sh
	";
          shellAliases = {
            vim = "nvim";
            ls = "colorls --gs";
            l = "ls -l";
            la = "ls -a";
            lla = "ls -la";
            lt = "ls --tree";
          };
        };

        starship = {
          enable = true;
          enableTransience = true;
          settings = {
            character = {
              error_symbol = "[ ](bold red)";
            };
            time = {
              disabled = false;
              time_format = "%T";
              utc_time_offset = "+1";
            };
            username = {
              style_user = "#00de00";
              style_root = "red";
              format = "[$user]($style) ";
              disabled = false;
              show_always = true;
            };
            hostname = {
              ssh_only = false;
              format = "@ [$hostname](bold yellow) ";
              disabled = false;
            };
            directory = {
              home_symbol = "󰋞 ~";
              read_only_style = "197";
              read_only = "  ";
              format = "at [$path]($style)[$read_only]($read_only_style) ";
            };
            git_metrics = {
              disabled = false;
              added_style = "bold blue";
              format = "[+$added]($added_style)/[-$deleted]($deleted_style) ";
            };
            git_status = {
              ahead = "↑$count(green)";
              behind = "↓$count(red)";
              diverged = "↕↓ahead_count(green)↑behind_count(red)";
              deleted = "✘$count";
              modified = "!$count";
              staged = "✚$count";
              renamed = "➜$count";
              untracked = "?$count";
            };
          };
        };

        zoxide = {
          enable = true;
          options = [
            "--cmd cd"
          ];
        };
      };
    };
}
