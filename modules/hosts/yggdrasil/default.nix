{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        teamviewer
        teams-for-linux

        pyfa
        obsidian
        diebahn

        path-of-building
      ];

      services.teamviewer.enable = true;
      environment.pathsToLink = [ "/libexec" ];

      programs.ssh.extraConfig = ''
        AddressFamily inet
      '';

      imports =
        with config.flake.modules.nixos;
        [
          inputs.nixos-hardware.nixosModules.common-cpu-amd
          inputs.nixos-hardware.nixosModules.common-pc
          inputs.nixos-hardware.nixosModules.common-pc-ssd
          inputs.catppuccin.nixosModules.catppuccin

          # System modules
          base
          dev
          desktop
          games

          # hardware
          audio
          bluetooth
          amdgpu

          # dektops
          hyprland
          niri

          # apps
          _1password

          # Users
          cholli
        ]
        ++ [
          {
            home-manager.users.cholli = {
              imports = with config.flake.modules.homeManager; [
                inputs.catppuccin.homeModules.catppuccin

                # components
                base
                dev

                # Activate all user based config
                cholli
              ];
            };
          }

        ];

      nix = {
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
        buildMachines = [
          {
            hostName = "nixberry";
            sshUser = "remotebuild";
            sshKey = "/root/.ssh/remotebuild";
            systems = [ "aarch64-linux" ];
            protocol = "ssh-ng";

            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "kvm"
            ];
          }
        ];
      };

    };
}
