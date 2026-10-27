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
        (protontricks.override {
          winetricks = winetricks.override {
            # CVE-2018-1000035, unpatched in nixpkgs; scoped here to avoid a mass rebuild
            unzip = unzip.overrideAttrs (old: {
              patches = old.patches ++ [
                (fetchpatch {
                  url = "https://sources.debian.org/data/main/u/unzip/6.0-31/debian/patches/cve-2018-1000035-unzip-buffer-overflow.patch";
                  hash = "sha256-d6kewEGQZXzKftFqN5MoqVhM6g1uTM5knzukcZCGY28=";
                })
              ];
            });
          };
        })
      ];
    };
}
