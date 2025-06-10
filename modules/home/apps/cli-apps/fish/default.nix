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
    catppuccin.fish.enable = true;

    programs = {
      fish = {
        enable = true;
        shellInit = ''
          zoxide init fish | source
          direnv hook fish | source

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
          ls = "eza -lah --icons --git";
          lss = "ls --total-size";
        };
        functions = {
          checkHash = "nix hash to-sri --type sha256 $(nix-prefetch-url --unpack $argv)";
          buildandDeployYggdrasil = "nom build '.#nixosConfigurations.yggdrasil.config.system.build.toplevel' && sudo nixos-rebuild switch --flake .#yggdrasil";
          deployNixberry = "nixos-rebuild switch --flake .#nixberry --target-host nixberry --use-remote-sudo --fast";
          deployLoptland = "nixos-rebuild switch --flake .#loptland --target-host christophhollizeck.dev --use-remote-sudo --fast";
          checkPR = "cd nixpkgs && ${lib.getExe pkgs.nixpkgs-review} pr $argv --post-result --approve";
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
