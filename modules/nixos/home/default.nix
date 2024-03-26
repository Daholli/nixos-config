{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.home;
in {
  options.wyrdgard.home = with types; {
    file =
      mkOpt attrs {}
      (mdDoc "A set of files to be managed by home-manager's `home.file`.");
    configFile =
      mkOpt attrs {}
      (mdDoc "A set of files to be managed by home-manager's `xdg.configFile`.");
    extraOptions = mkOpt attrs {} "Options to pass directly to home-manager.";
  };

  config = {
    wyrdgard.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.wyrdgard.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.wyrdgard.home.configFile;
    };

    snowfallorg.user.${config.wyrdgard.user.name}.home.config = config.wyrdgard.home.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
