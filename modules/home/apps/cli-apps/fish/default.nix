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

  config = mkIf cfg.enable {
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
            success_symbol = "[➜](bold green)";
            error_symbol = "[✗](bold red) ";
            vicmd_symbol = "[](bold blue) ";
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
