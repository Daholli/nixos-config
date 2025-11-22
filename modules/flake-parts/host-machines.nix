{
  inputs,
  lib,
  config,
  ...
}:
let
  prefix = "hosts/";
  collectHostsModules = modules: lib.filterAttrs (name: _: lib.hasPrefix prefix name) modules;
in
{
  flake.nixosConfigurations = lib.pipe (collectHostsModules config.flake.modules.nixos) [
    (lib.mapAttrs' (
      name: module:
      let
        raspberrypis = [ "nixberry" ];

        stripped_name = lib.removePrefix prefix name;

        specialArgs = {
          inherit inputs;
          hostConfig = module // {
            name = stripped_name;
          };

          nixos-raspberrypi = lib.mkIf (builtins.elem stripped_name raspberrypis) inputs.nixos-raspberrypi;
        };
      in
      {
        name = stripped_name;
        value =
          if builtins.elem stripped_name raspberrypis then
            inputs.nixos-raspberrypi.lib.nixosSystem {
              inherit specialArgs;
              modules = module.imports ++ [
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.extraSpecialArgs = specialArgs;
                }
              ];
            }
          else
            inputs.nixpkgs.lib.nixosSystem {
              inherit specialArgs;
              modules = module.imports ++ [
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.extraSpecialArgs = specialArgs;
                }
              ];
            };
      }
    ))
  ];

  flake.installerImages = inputs.nixos-raspberrypi-installers.installerImages;

  flake.hydraJobs =
    let
      self = inputs.self;
    in
    {
      hosts = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.outputs.nixosConfigurations;
      installerImages = {
        rpi5 = self.outputs.installerImages.rpi5;
      };
      packages = self.packages;
      shells = lib.filterAttrs (name: shell: name == "x86_64-linux") self.devShells;
    };
}
