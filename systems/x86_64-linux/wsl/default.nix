{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
{
  wsl = {
    enable = true;
    defaultUser = config.wyrdgard.user.name;
  };

  wyrdgard = {
    submodules.basics-wsl = enabled;

    security = {
      gpg = enabled;
      sops = enabled;
    };
  };

  programs.dconf.enable = true;

  system.stateVersion = "24.11";
}
