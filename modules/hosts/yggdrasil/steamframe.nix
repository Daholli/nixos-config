{
  flake.modules.nixos."hosts/yggdrasil" =
    { lib, pkgs, ... }:
    let
      toggles = pkgs.stdenvNoCC.mkDerivation {
        pname = "holo-realtek-firmware-toggles";
        version = "1.4-1";

        src = pkgs.fetchurl {
          url = "https://steamdeck-packages.steamos.cloud/archlinux-mirror/holo-main/os/x86_64/holo-realtek-firmware-toggles-1.4-1-any.pkg.tar.zst";
          hash = "sha256-jXr+kV0QzMWiv+0JBv7estA1k8svYM15Ct6XHwZQr1k=";
        };

        nativeBuildInputs = [
          pkgs.zstd
          pkgs.makeWrapper
        ];

        unpackPhase = "tar --zstd -xf $src";

        installPhase = ''
          install -Dm755 usr/bin/holo-polkit-helpers/holo-realtek-firmware-toggles \
            $out/bin/holo-realtek-firmware-toggles
          wrapProgram $out/bin/holo-realtek-firmware-toggles --prefix PATH : ${
            lib.makeBinPath [
              pkgs.iw
              pkgs.findutils
              pkgs.coreutils
              pkgs.gnugrep
            ]
          }
        '';

        meta.mainProgram = "holo-realtek-firmware-toggles";
      };
      t = lib.getExe toggles;
    in
    {
      # Steam calls this helper from its bwrap sandbox, where pkexec can't elevate,
      # so NM applies Valve's low-latency mode instead (minus the -75 dBm static PD threshold)
      networking.networkmanager.dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "steam-frame-low-latency" ''
            [ "$CONNECTION_ID" = "Steam Frame Wireless Adapter" ] || exit 0
            case "$2" in
              up)
                ${t} set-feature HW_SCAN off
                ${t} set-amsdu off
                ${t} set-mcs-rates 0-9
                ${t} set-powersave off
                ;;
              down)
                # no MCS reset: `iw set bitrates` while unassociated oopses rtw89
                ${t} set-feature HW_SCAN on
                ${t} set-powersave on
                ${t} set-amsdu on
                ;;
            esac
          '';
        }
      ];

      environment.systemPackages = [ toggles ];
    };
}
