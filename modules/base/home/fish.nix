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
      {
        lib,
        osConfig,
        pkgs,
        ...
      }:
      {
        catppuccin.fish.enable = true;

        programs = {
          fish = {
            enable = true;
            shellInit = ''
              # Auto-start Tmux on SSH login  
              if test -n "$SSH_TTY" && test -z "$TMUX"  
                if command -v tmux > /dev/null 2>&1  
                  if tmux has-session -t ssh-auto 2>/dev/null  
                    tmux attach-session -t ssh-auto  
                  else  
                    tmux new-session -s ssh-auto  
                  end  
                end  
              end
            '';
            shellAliases = {
              vim = "hx";
              ls = "eza -lah --icons --git";
              lss = "ls --total-size";
              lt = "ls -T --git-ignore";
            };
            functions = {
              checkHash = "nix hash to-sri --type sha256 $(nix-prefetch-url --unpack $argv)";
              deployNixberry = "${lib.getExe osConfig.programs.nh.package} os switch --target-host nixberry -H nixberry";
              deployLoptland = "${lib.getExe osConfig.programs.nh.package} os switch --target-host christophhollizeck.dev -H loptland";
              exportMachineSSHkey = "export SOPS_AGE_KEY=$(sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -private-key)
";
              checkPR = ''cd /home/cholli/projects/NixOS/nixpkgs && ${lib.getExe pkgs.nixpkgs-review} pr $argv --post-result --systems "x86_64-linux aarch64-linux"'';

              syncfactoriomodstoserver = ''rsync -aP ~/.factorio/mods/ root@loptland:/var/lib/factorio/mods/ --delete && ssh root@loptland "systemctl restart systemd-tmpfiles-resetup.service && systemctl restart factorio.service"'';
            };
            plugins = with pkgs.fishPlugins; [
              {
                name = "forgit";
                src = forgit.src;
              }
            ];
          };

          yazi = {
            enable = true;
          };

          zoxide = {
            enable = true;
            options = [ "--cmd cd" ];
          };

        };
      };
  };
}
