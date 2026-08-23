{
  flake.modules.nixos.games =
    { inputs, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        prismlauncher
        starsector
        beyond-all-reason

        inputs.titrack.packages.${pkgs.stdenv.hostPlatform.system}.default

        # gaming tools
        pyfa
        inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rusty-path-of-building
      ];
    };
}
