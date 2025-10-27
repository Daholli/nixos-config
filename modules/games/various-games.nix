{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        prismlauncher
        starsector
      ];
    };
}
