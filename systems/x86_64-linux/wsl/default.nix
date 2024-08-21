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

  environment.systemPackages = with pkgs; [
    git
    wslu
    wsl-open
  ];

  wyrdgard = {
    submodules.basics-wsl = enabled;
  };

  system.stateVersion = "24.11";
}
