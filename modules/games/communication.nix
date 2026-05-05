{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        vesktop
        teamspeak6-client
        element-desktop
      ];

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-move-transition
        ];
      };
    };
}
