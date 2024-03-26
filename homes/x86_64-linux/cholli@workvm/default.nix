{ lib
, pkgs
, config
, ...
}:
# User information gathered by Snowfall Lib is available.
let
  name = config.snowfallorg.user.name;
  home = config.snowfallorg.user.home.directory;
in
{
  home = {
    packages = with pkgs; [ neovim ];

    sessionVariables = { EDITOR = "nvim"; };

    shellAliases = {
      vim = "nvim";
      vimdiff = "nvim -d";
    };

    stateVersion = "23.11";
  };
}
