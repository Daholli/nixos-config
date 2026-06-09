{
  flake.modules = {
    homeManager.cholli = _: {
      catppuccin.kitty.enable = true;
      home.sessionVariables = {
        TERMINAL = "kitty";
        PRE_COMMIT_COLOR = "never";
      };
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
    };
  };
}
