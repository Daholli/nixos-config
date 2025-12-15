{
  flake.modules = {
    homeManager.cholli =
      { pkgs, ... }:
      {
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
          };
        };

        #   catppuccin.ghostty.enable = true;
        #   programs.ghostty = {
        #     enable = true;
        #     enableFishIntegration = true;
        #     installVimSyntax = true;
        #     settings = {
        #       font-family = "FiraCode Nerd Font";
        #       font-size = 15;
        #       font-codepoint-map = "U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0C8,U+E0CA,U+E0CC-U+E0D7,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6B7,U+E700-U+E8EF,U+EA60-U+EC1E,U+ED00-U+F2FF,U+EE00-U+EE0B,U+F300-U+F381,U+F400-U+F533,U+F0001-U+F1AF0=Symbols Nerd Font";
        #       background-opacity = 0.9;
        #       clipboard-paste-protection = true;
        #       confirm-close-surface = false;
        #       mouse-scroll-multiplier = 0.3;
        #     };
        #   };
      };
  };
}
