{ ... }:
final: prev: {
  starsector = prev.starsector.overrideAttrs (prevAttrs: {
    postInstall = ''
      wrapProgram $out/bin/starsector --set __GL_THREADED_OPTIMIZATIONS 0
    '';
  });
}
