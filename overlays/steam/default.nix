{ ... }:

final: prev: {
  steam = prev.steam.overrideAttrs (oldAttrs: {
    commandLineArgs = ''
      --disable-gpu-compositing
    '';
  });
}
