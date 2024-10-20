{
  config,
  lib,
  namespace,
  options,
  pkgs,
  ...
}:
with lib.${namespace};
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.cli-apps.fish;
in
{
  options.${namespace}.apps.cli-apps.fish = {
    enable = mkBoolOpt true "Whether or not to enable the fish shell";
  };

  config = mkIf cfg.enable {
    programs = {
      fish = {
        enable = true;
        shellInit = ''
          zoxide init fish | source
          direnv hook fish | source
          source ~/.config/op/plugins.sh

          set -x LESS_TERMCAP_mb \e'[01;32m'
          set -x LESS_TERMCAP_md \e'[01;32m'
          set -x LESS_TERMCAP_me \e'[0m'
          set -x LESS_TERMCAP_se \e'[0m'
          set -x LESS_TERMCAP_so \e'[01;47;34m'
          set -x LESS_TERMCAP_ue \e'[0m'
          set -x LESS_TERMCAP_us \e'[01;36m'
          set -x LESS -R
          set -x GROFF_NO_SGR 1
        '';
        shellAliases = {
          vim = "hx";
          ls = "colorls --gs -A";
          ll = "ls -l";
          lt = "colorls --tree";
        };
        plugins = with pkgs.fishPlugins; [
          {
            name = "forgit";
            src = forgit.src;
          }
        ];
      };

      zoxide = {
        enable = true;
        options = [ "--cmd cd" ];
      };
    };
  };
}
