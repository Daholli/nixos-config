{
  flake.modules.nixos.games =
    { inputs, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        prismlauncher
        starsector

        # gaming tools
        pyfa
        inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.rusty-path-of-building
      ];
    };
}
