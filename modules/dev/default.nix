topLevel: {
  # Hosts that import the `dev` NixOS module also get the dev home-manager config.
  flake.modules.nixos.dev = {
    home-manager.users.cholli.imports = [ topLevel.config.flake.modules.homeManager.dev ];
  };
}
