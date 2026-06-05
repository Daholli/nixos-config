{
  flake.modules = {
    homeManager.cholli = _: {
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
          background_opacity = 0.9;
          shell = "fish";
          confirm_os_window_close = 0;
          auto_reload_config = -1;
        };
      };
    };
  };
}
