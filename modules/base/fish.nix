{
  flake.modules = {
    nixos.base =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          fastfetch

          fd
          tree
          ripgrep
          fzf
          eza

          #optional
          pciutils
          usbutils
          btop

          zip
          unzip
          nettools
        ];
      };

    homeManager.base =
      { lib, pkgs, ... }:
      {
        catppuccin.fish.enable = true;

        programs = {
          fish = {
            enable = true;
            shellInit = ''
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
              lt = "ls -T --git-ignore";
            };
            functions = {
              checkHash = "nix hash to-sri --type sha256 $(nix-prefetch-url --unpack $argv)";
              deployNixberry = "nixos-rebuild switch --flake .#nixberry --target-host nixberry --sudo --ask-sudo-password";
              deployLoptland = "nixos-rebuild switch --flake .#loptland --target-host christophhollizeck.dev --sudo --ask-sudo-password";
              checkPR = ''cd /home/cholli/projects/NixOS/nixpkgs && ${lib.getExe pkgs.nixpkgs-review} pr $argv --post-result --systems "x86_64-linux aarch64-linux"'';
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
  };
}
