{ ... }:

final: prev: {
  discord = prev.discord.overrideAttrs (oldAttrs: {
    commandLineArgs = ''
      --disable-gpu-compositing
    '';
  });
}
