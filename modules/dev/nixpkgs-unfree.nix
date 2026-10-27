{
  flake.modules.homeManager.dev = {
    xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
    home.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
  };
}
