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
            "background_opacity" = "0.90";
            "shell" = "fish";
            "confirm_os_window_close" = "0";
          };
        };

        catppuccin.ghostty.enable = true;
        programs.ghostty = {
          enableFishIntegration = true;
          installVimSyntax = true;

          settings = {

          };

        };

      };
  };
}
