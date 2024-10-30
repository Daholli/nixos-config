{ ... }:

final: prev: {
  teams-for-linux = prev.teams-for-linux.overrideAttrs (oldAttrs: {
    commandLineArgs = ''
      --disable-gpu-compositing
    '';
  });
}
