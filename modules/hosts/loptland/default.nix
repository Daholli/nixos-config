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
      domainName = "christophhollizeck.dev";
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
          hydra
          forgejo
          factorio-server

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

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      networking.firewall.allowedTCPPorts = [
        3000
        80
        443
      ];

    };
}
