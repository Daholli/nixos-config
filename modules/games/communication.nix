{ inputs, ... }:
{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        discord
        # teamspeak6-client
        inputs.sable.packages.${pkgs.stdenv.hostPlatform.system}.sable-desktop
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
