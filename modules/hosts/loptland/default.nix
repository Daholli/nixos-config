{
  config,
  ...
}:
let
in
{
  flake.modules.nixos."hosts/loptland" =
    {
      inputs,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    let
      sopsFile = ../../../secrets/secrets-loptland.yaml;

    in
    {
      nixpkgs.config.allowUnfree = true;
      services.qemuGuest.enable = true;

      imports =
        with config.flake.modules.nixos;
        [
          (modulesPath + "/profiles/qemu-guest.nix")
          inputs.catppuccin.nixosModules.catppuccin

          # System modules
          base
          server

          # apps

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

                # Activate all user based config
                cholli
              ];
            };
          }

        ];

      sops = {
        secrets = {
          "forgejo/db/password" = {
            inherit sopsFile;
          };
          "forgejo/mail/password" = {
            inherit sopsFile;
          };
          "forgejo/mail/passwordHash" = {
            inherit sopsFile;
          };
        };
      };

    };
}
