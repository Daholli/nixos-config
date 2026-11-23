{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.sable-desktop =
        let
          launcher = pkgs.writeShellApplication {
            name = "sable-desktop";
            text = ''exec ${lib.getExe pkgs.chromium} --app=https://chat.alwayssleepy.online/ "$@"'';
          };
        in
        pkgs.symlinkJoin {
          name = "sable-desktop";
          paths = [
            launcher
            (pkgs.makeDesktopItem {
              name = "sable";
              desktopName = "Sable";
              exec = "sable-desktop";
              icon = "${pkgs.sable-unwrapped.src}/public/full_res_sable_square.png";
              categories = [
                "Network"
                "InstantMessaging"
                "Chat"
              ];
            })
          ];
          meta.mainProgram = "sable-desktop";
        };
    };
}
