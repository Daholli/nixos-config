{
  flake.modules.nixos.games =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        package = pkgs.steam.override {
          extraArgs = "-pipewire -vrlinkforceenable";
          extraBwrapArgs = [ "--unsetenv TZ" ];
          # SteamVR's bundled Qt only ships xcb and can't parse "wayland;xcb"
          extraEnv.QT_QPA_PLATFORM = "xcb";
        };
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      environment.systemPackages = with pkgs; [
        protontricks
      ];
    };
}
