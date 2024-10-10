{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.cli-apps.nixvim;
in
{
  options.${namespace}.apps.cli-apps.nixvim = {
    enable = mkBoolOpt false "Whether to enable nixvim or not (Default true)";
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
        PAGER = "less";
        MANPAGER = "less";
      };
    };

    ${namespace}.home = {
      extraOptions = {
        # Use Neovim for Git diffs.
        programs.fish.shellAliases.vimdiff = "nvim -d";
      };
    };
  };
}
