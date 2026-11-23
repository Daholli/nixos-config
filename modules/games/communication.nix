{ withSystem, ... }:
{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        vesktop
        # teamspeak6-client
        (withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.sable-desktop))
      ];

      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-pipewire-audio-capture
          input-overlay
          obs-vaapi
        ];
      };
    };
}
