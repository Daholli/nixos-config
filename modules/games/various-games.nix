{
  flake.modules.nixos.games =
    { inputs, pkgs, ... }:
    {
      imports = [
        inputs.titrack.nixosModules.default
      ];

      environment.systemPackages = with pkgs; [
        prismlauncher
        starsector

        # gaming tools
        pyfa
        inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rusty-path-of-building
      ];

      services.titrack = {
        enable = true;
      };
    };
}
