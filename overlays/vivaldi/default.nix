{ channels, ... }:

final: prev: {
  vivaldi = prev.vivaldi.overrideAttrs (oldAttrs: {
    dontWrapQtApps = false;
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ channels.unstable.kdePackages.wrapQtAppsHook ];
    commandLineArgs = ''
      -enable-features=UseOzonePlatform
      --ozone-platform=wayland
      --ozone-platform-hint=auto
      --enable-features=WaylandWindowDecorations 
    '';
  });
}
