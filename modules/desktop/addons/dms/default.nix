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

          enableVPN = false;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = false;
        };
      };
    };
}
