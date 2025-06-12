{ ... }:
final: prev: {
  path-of-building = prev.path-of-building.overrideAttrs (prevAttrs: {
    postInstall = ''
      wrapProgram $out/bin/pobfrontend --set QT_QPA_PLATFORM xcb
    '';
  });
}
