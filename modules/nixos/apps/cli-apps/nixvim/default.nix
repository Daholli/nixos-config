{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.wyrdgard) mkBoolOpt;
  cfg = config.wyrdgard.apps.cli-apps.nixvim;
in
{
  options.wyrdgard.apps.cli-apps.nixvim = {
    enable = mkBoolOpt true "Whether to enable nixvim or not (Default true)";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        less
        nvim-pkg
      ];
      variables = {
        EDITOR = "nvim";
        SUDOEDITOR = "nvim";
      };
    };

    wyrdgard.home = {
      extraOptions = {
        # Use Neovim for Git diffs.
        programs.fish.shellAliases.vimdiff = "nvim -d";
      };
    };
  };
}
