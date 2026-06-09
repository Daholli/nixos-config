{
  flake.modules = {
    homeManager.cholli =
      { osConfig, ... }:
      {
        services.kdeconnect = {
          enable = osConfig.programs.kdeconnect.enable;
        };

        xdg.mimeApps.defaultApplications."x-scheme-handler/kdeconnect" = "org.kde.dolphin.desktop";
      };

    nixos.kdeconnect = _: {
      programs.kdeconnect.enable = true;
    };
  };
}
