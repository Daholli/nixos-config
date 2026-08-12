{
  flake.modules.homeManager.cholli =
    {
      inputs,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      settingsSrc =
        if osConfig.networking.hostName == "wsl" then
          pkgs.writeText "dms-settings.json" (
            builtins.toJSON (
              let
                base = builtins.fromJSON (builtins.readFile ./settings.json);
              in
              base
              // {
                screenPreferences = { };
                barConfigs = map (b: b // { screenPreferences = [ "all" ]; }) (base.barConfigs or [ ]);
                currentThemeName = "purple";
                currentThemeCategory = "stock";
                customThemeFile = "";
                runUserMatugenTemplates = false;
                acLockTimeout = 0;
                batteryLockTimeout = 0;
                fadeToLockEnabled = false;
                loginctlLockIntegration = false;
              }
            )
          )
        else
          ./settings.json;
    in
    {
      imports = [
        inputs.dankMaterialShell.homeModules.dank-material-shell
        inputs.dankMaterialShell.homeModules.niri
        inputs.danksearch.homeModules.dsearch
      ];

      config = lib.mkIf osConfig.programs.niri.enable {
        home.file = {
          # https://www.reddit.com/r/WidescreenWallpaper/comments/13hib3t/purple_firewatch_3840x1620/
          "Pictures/firewatch_background.jpg".source = ../../../../assets/firewatch_background.jpg;
          # https://wallpaperaccess.com/galaxy-nebula
          "Pictures/nebula_background.jpg".source = ../../../../assets/nebula_background.jpg;
          "Pictures/horizon-zero-dawn-aloy.jpg".source = ../../../../assets/horizon-zero-dawn-aloy.jpg;
          "Pictures/scifi_planet.jpg".source = ../../../../assets/scifi_planet.jpg;
        };

        home.activation.dmsWritableConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          seed() {
            target="$HOME/.config/DankMaterialShell/$1"
            if [ -L "$target" ] || [ ! -e "$target" ]; then
              $DRY_RUN_CMD rm -f "$target"
              $DRY_RUN_CMD install -Dm0644 "$2" "$target"
            fi
          }
          seed settings.json ${settingsSrc}
          seed clsettings.json ${./clsettings.json}
        '';

        programs.dank-material-shell = {
          enable = true;
          niri = {
            enableSpawn = true;
            enableKeybinds = true;

            includes.enable = false;
          };

          # dgop.package = inputs.dgop.packages.${pkgs.stdenv.system}.default;

          plugins.dankDiskUsage = {
            enable = true;
            src = inputs.dms-plugin-diskusage;
          };

          enableVPN = false;
          enableDynamicTheming = false;
          enableAudioWavelength = false;
          enableCalendarEvents = false;
        };

        programs.dsearch.enable = true;
      };
    };
}
