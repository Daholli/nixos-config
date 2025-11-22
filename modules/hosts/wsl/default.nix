topLevel: {
  flake.modules.nixos."hosts/wsl" =
    {
      inputs,
      lib,
      ...
    }:
    {
      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = lib.systems.elaborate "x86_64-linux";
      };
      programs.dconf.enable = true;

      imports =
        with topLevel.config.flake.modules.nixos;
        [
          inputs.nixos-wsl.nixosModules.default

          base
          cholli
        ]

        ++ [
          {
            home-manager.users.cholli = {
              imports = with topLevel.config.flake.modules.homeManager; [
                inputs.catppuccin.homeModules.catppuccin

                # components
                base

                # Activate all user based config
                cholli
              ];
            };
          }
        ];
      wsl = {
        enable = true;
        defaultUser = topLevel.config.flake.meta.users.cholli.username;

        usbip = {
          enable = true;
          autoAttach = [ "3-1" ];
        };
      };

    };
}
