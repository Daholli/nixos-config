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

        zoxide = {
          enable = true;
          options = [
            "--cmd cd"
          ];
        };
      };
    };
}
