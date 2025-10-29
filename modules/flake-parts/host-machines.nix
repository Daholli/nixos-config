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
        specialArgs = {
          inherit inputs;
          hostConfig = module // {
            name = lib.removePrefix prefix name;
          };
        };
      in
      {
        name = lib.removePrefix prefix name;
        value = inputs.nixpkgs.lib.nixosSystem {
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

  flake.hydraJobs =
    let
      self = inputs.self;
    in
    {
      # hosts = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.outputs.nixosConfigurations;
      packages = self.packages;
      shells = lib.filterAttrs (name: shell: name == "x86_64-linux") self.devShells;
    };
}
