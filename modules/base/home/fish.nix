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
          jq

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
                name = "sponge";
                src = pkgs.fishPlugins.sponge.src;
              }
              {
                name = "fzf-fish";
                src = pkgs.fishPlugins.fzf-fish.src;
              }
            ];
            shellInit = ''
              if command -q devenv
                devenv hook fish | source
              end

              # Auto-configure tide on first run
              if not set -q tide_left_prompt_items
                tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Compact --icons='Many icons' --transient=Yes
                catppuccin_tide mocha lean
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
              deployNixberry = "${lib.getExe osConfig.programs.nh.package} os switch --build-host nixberry --target-host nixberry -H nixberry $argv";
              deployLoptland = "${lib.getExe osConfig.programs.nh.package} os switch --target-host christophhollizeck.dev -H loptland $argv";
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
