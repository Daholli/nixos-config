{
  flake.modules.homeManager.cholli =
    {
      inputs,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.dankMaterialShell.homeModules.dank-material-shell
        inputs.dankMaterialShell.homeModules.niri
      ];

      config = lib.mkIf osConfig.programs.niri.enable {
        home.file = {
          ".config/DankMaterialShell/settings.json".source = ./settings.json;
          ".config/DankMaterialShell/clsettings.json".source = ./clsettings.json;
          # https://www.reddit.com/r/WidescreenWallpaper/comments/13hib3t/purple_firewatch_3840x1620/
          "Pictures/firewatch_background.jpg".source = ../../../../assets/firewatch_background.jpg;
          # https://wallpaperaccess.com/galaxy-nebula
          "Pictures/nebula_background.jpg".source = ../../../../assets/nebula_background.jpg;
        };

        programs.dank-material-shell = {
          enable = true;
          niri = {
            enableSpawn = true;
            enableKeybinds = true;

            includes.enable = false;
          };

          dgop.package = inputs.dgop.packages.${pkgs.stdenv.system}.default;

          enableVPN = false;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = false;
        };
      };
    };
}
