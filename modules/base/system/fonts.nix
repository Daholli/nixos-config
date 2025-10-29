{

  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.variables = {
        # Enable icons in tooling since we have nerdfonts.
        LOG_ICONS = "true";
      };

      fonts.packages = with pkgs; [
        font-awesome
        powerline-fonts
        powerline-symbols
        nerd-fonts.code-new-roman
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        fira
      ];

    };
}
