_: {
  # CI configuration for omnix (om ci).
  # devour-flake (used by om ci) automatically picks up:
  #   packages, apps, checks, devShells, nixosConfigurations.*
  flake.om.ci.default = {
    x86_64 = {
      dir = ".";
      systems = [ "x86_64-linux" ];
      steps.flake-check.enable = false;
    };
    aarch64 = {
      dir = ".";
      systems = [ "aarch64-linux" ];
      steps.flake-check.enable = false;
    };
  };
}
