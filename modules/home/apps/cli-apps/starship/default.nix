{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.cli-apps.starship;
in
{
  options.wyrdgard.apps.cli-apps.starship = with types; {
    enable = mkBoolOpt true "Whether or not to enable starship shell";
  };

  config = mkIf cfg.enable {
    programs = {
      fish.shellInit = "
	starship init fish | source
      ";

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
            utc_time_offset = "+2";
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
            format = "([$all_status$ahead_behind]($style) )";
            ahead = "[↑$count](bold green)";
            behind = "[↓$count](bold red)";
            diverged = "[↕↓$ahead_count↑$behind_count](red)";
            deleted = "[✘$count](red) ";
            modified = "[!$count](yellow) ";
            staged = "[+$count](green) ";
            renamed = "[➜$count](green) ";
            untracked = "[?$count](blue) ";
          };
        };
      };
    };
  };
}
