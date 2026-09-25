{
  flake.modules = {
    homeManager.cholli =
      { lib, osConfig, ... }:
      lib.mkMerge [
        {
          home.sessionVariables.PRE_COMMIT_COLOR = "never";
        }
        (lib.mkIf osConfig.programs.niri.enable {
          catppuccin.kitty.enable = true;
          home.sessionVariables.TERMINAL = "kitty";

          programs.kitty = {
            enable = true;
            font = {
              name = "FiraCode Nerd Font";
              size = 15;
            };
            shellIntegration.enableFishIntegration = true;
            settings = {
              shell = "fish";
              confirm_os_window_close = 0;
              auto_reload_config = -1;
            };
          };
        })
      ];
  };
}
