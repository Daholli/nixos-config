{ ... }:

final: prev: {
  obsidian = prev.obsidian.overrideAttrs (oldAttrs: rec {
    # Add arguments to the .desktop entry
    desktopItem = oldAttrs.desktopItem.override (desktopitem: {
      exec = "${desktopitem.exec} --disable-gpu ";
    });

    # Update the install script to use the new .desktop entry
    installPhase = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ] [
      "${desktopItem}"
    ] oldAttrs.installPhase;
  });
}
