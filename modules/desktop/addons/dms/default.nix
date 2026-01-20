{
  flake.modules.homeManager.cholli =
    {
      inputs,
      lib,
      osConfig,
      ...
    }:
    let
      picture-path = "/home/cholli/Pictures/firewatch.jpg";
    in
    {
      imports = [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
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

        programs.dankMaterialShell = {
          enable = true;
          niri = {
            enableKeybinds = true;
            enableSpawn = true;
          };

          enableVPN = false;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = false;
        };
      };
    };
}
