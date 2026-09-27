{
  flake.modules = {
    homeManager.cholli =
      { osConfig, pkgs, ... }:
      {
        services.kdeconnect = {
          enable = osConfig.programs.kdeconnect.enable;
        };

        xdg.configFile."systemd/user/app-org.kde.kdeconnect.daemon@autostart.service.d/wait-tray.conf" = {
          enable = osConfig.programs.kdeconnect.enable;
          text = ''
            [Service]
            ExecStartPre=-${pkgs.glib}/bin/gdbus wait --session --timeout 30 org.kde.StatusNotifierWatcher
          '';
        };

        xdg.mimeApps.defaultApplications."x-scheme-handler/kdeconnect" = "org.kde.dolphin.desktop";
      };

    nixos.kdeconnect = _: {
      programs.kdeconnect.enable = true;
    };
  };
}
