{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      environment.systemPackages = with pkgs; [
        protontricks
      ];
    };
}
