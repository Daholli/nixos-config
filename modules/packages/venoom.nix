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
            glibc,
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

          let
            # glibc 2.43 for the vendored livekit plugin, which needs sqrtf/log10f@GLIBC_2.43.
            # nixpkgs is on 2.42 (master and staging, 2026-09; upstream is at 2.44).
            # Not nixpkgs' tested glibc: no upstream patch stack, -Werror off.
            # Only the Venoom binary uses it; everything else stays on 2.42.
            glibc243 = glibc.overrideAttrs (old: {
              version = "2.43";

              src = fetchurl {
                url = "mirror://gnu/glibc/glibc-2.43.tar.xz";
                hash = "sha256-2chsa12920Oj4IJwxYRPxRd9GUQs9bjfS+fAfNX6ODE=";
              };

              patches = builtins.filter (
                p:
                !(
                  # Post-2.42 backport; cannot apply to 2.43.
                  lib.hasInfix "2.42-master" (toString p)
                  # No longer applies to 2.43's shell scripts.
                  || lib.hasInfix "Remove-all-usage-of-BASH" (toString p)
                )
              ) old.patches;

              # glibc 2.43 and linux-headers 7.1 both define OPEN_TREE_CLONE. Same value,
              # different token list (kernel uses `#define X X`), so -Werror rejects it.
              configureFlags = (old.configureFlags or [ ]) ++ [ "--disable-werror" ];
            });
          in
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

            # Must run after autoPatchelfHook, which resets the interpreter; postFixup
            # runs before it. ld.so resolves libc/libm once by soname from this RPATH,
            # so 2.43 first here covers the whole process.
            postPhases = [ "useGlibc243Phase" ];
            useGlibc243Phase = ''
              patchelf \
                --set-interpreter ${glibc243}/lib/ld-linux-x86-64.so.2 \
                --set-rpath "${glibc243}/lib:$(patchelf --print-rpath $out/share/venoom/venoommobile)" \
                $out/share/venoom/venoommobile
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
