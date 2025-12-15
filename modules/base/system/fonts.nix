{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      fonts = {
        enableDefaultPackages = true;

        packages = with pkgs; [
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
          nerd-fonts.symbols-only
        ];

        fontconfig = {
          useEmbeddedBitmaps = true;
        };
      };
    };
}
