{ withSystem, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        venoom = pkgs.callPackage (
          {
            lib,
            stdenv,
            fetchurl,
            autoPatchelfHook,
            makeWrapper,
            wrapGAppsHook3,
            adwaita-icon-theme,
            alsa-lib,
            atk,
            cairo,
            fontconfig,
            gdk-pixbuf,
            glib,
            gst_all_1,
            gtk3,
            harfbuzz,
            keybinder3,
            libdrm,
            libepoxy,
            libgbm,
            libglvnd,
            libpulseaudio,
            libsecret,
            libx11,
            libxcomposite,
            libxdamage,
            libxext,
            libxfixes,
            libxrandr,
            mpv-unwrapped,
            pango,
            pipewire,
            zlib,
          }:

          stdenv.mkDerivation {
            pname = "venoom";
            version = "1.1.0+1";

            src = fetchurl {
              url = "https://github.com/drvnm/venoom-releases/releases/download/linux-v1.1.0%2B1/Venoom-1.1.0%2B1-linux-x64.tar.gz";
              hash = "sha256-EmBSWaNimjS9XTa3CHh+XlFvtmbjP988hykO0MfY7iU=";
            };

            sourceRoot = "bundle";

            nativeBuildInputs = [
              autoPatchelfHook
              makeWrapper
              wrapGAppsHook3
            ];

            buildInputs = [
              adwaita-icon-theme
              atk
              cairo
              fontconfig
              gdk-pixbuf
              glib
              gst_all_1.gst-plugins-base
              gst_all_1.gstreamer
              gtk3
              harfbuzz
              keybinder3
              libdrm
              libepoxy
              libgbm
              libpulseaudio
              libsecret
              libx11
              libxcomposite
              libxdamage
              libxext
              libxfixes
              libxrandr
              mpv-unwrapped
              pango
              stdenv.cc.cc.lib
              zlib
            ];

            # dlopen'd at runtime, so invisible to autoPatchelfHook.
            runtimeDependencies = [
              alsa-lib
              libglvnd
              libgbm
              libpulseaudio
              pipewire
            ];

            # wrapGAppsHook3 would wrap the bin/ symlink; wrap by hand instead.
            dontWrapGApps = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/venoom
              cp -r data lib venoommobile $out/share/venoom/

              install -Dm444 share/applications/net.venoom.app.desktop \
                -t $out/share/applications

              runHook postInstall
            '';

            postFixup = ''
              makeWrapper $out/share/venoom/venoommobile $out/bin/venoommobile \
                "''${gappsWrapperArgs[@]}" \
                --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0" \
                --prefix LD_LIBRARY_PATH : "$out/share/venoom/lib"

              substituteInPlace $out/share/applications/net.venoom.app.desktop \
                --replace-fail "Exec=venoommobile" "Exec=$out/bin/venoommobile"
            '';

            meta = {
              description = "Voice and text chat client";
              homepage = "https://github.com/drvnm/venoom-releases";
              license = lib.licenses.agpl3Plus;
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
              platforms = [ "x86_64-linux" ];
              mainProgram = "venoommobile";
            };
          }
        ) { };
      };
    };

  flake.modules.nixos.venoom =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.venoom))
      ];
    };
}
