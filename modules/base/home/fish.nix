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
        inputs,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      {
        programs = {
          fish = {
            enable = true;
            plugins = [
              {
                name = "tide";
                src = pkgs.fishPlugins.tide.src;
              }
              {
                name = "catppuccin-tide";
                src = inputs.catppuccin-tide;
              }
              {
                name = "done";
                src = pkgs.fishPlugins.done.src;
              }
              {
                name = "fifc";
                src = pkgs.fishPlugins.fifc.src;
              }
              {
                name = "sponge";
                src = pkgs.fishPlugins.sponge.src;
              }
            ];
            shellInit = ''
              devenv hook fish | source

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
              bs = "but status";
            };
            functions = {
              checkHash = "nix hash to-sri --type sha256 $(nix-prefetch-url --unpack $argv)";
              deployNixberry = "${lib.getExe osConfig.programs.nh.package} os switch --build-host nixberry --target-host nixberry -H nixberry";
              deployLoptland = "${lib.getExe osConfig.programs.nh.package} os switch --target-host christophhollizeck.dev -H loptland";
              exportMachineSSHkey = "export SOPS_AGE_KEY=$(sudo ssh-to-age -i /etc/ssh/ssh_host_ed25519_key -private-key)";
              checkPR = ''cd /home/cholli/projects/NixOS/nixpkgs && ${lib.getExe pkgs.nixpkgs-review} pr $argv --post-result --systems "x86_64-linux aarch64-linux"'';

              syncfactoriomodstoserver = ''rsync -aP ~/.factorio/mods/ root@loptland:/var/lib/factorio/mods/ --delete && ssh root@loptland "systemctl restart systemd-tmpfiles-resetup.service && systemctl restart factorio.service"'';
            };
          };

          yazi = {
            enable = true;
            shellWrapperName = "y";
          };

          zoxide = {
            enable = true;
            enableFishIntegration = true;
            options = [ "--cmd=cd" ];
          };
        };
      };
  };
}
