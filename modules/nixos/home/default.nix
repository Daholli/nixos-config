{
  config,
  lib,
  namespace,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = with types; {
    file = mkOpt attrs { } (mdDoc "A set of files to be managed by home-manager's `home.file`.");
    configFile = mkOpt attrs { } (
      mdDoc "A set of files to be managed by home-manager's `xdg.configFile`."
    );
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    snowfallorg.users.${config.${namespace}.user.name}.home.config = mkMerge [
      {
        home.stateVersion = config.system.stateVersion;
        home.file = mkAliasDefinitions options.${namespace}.home.file;
        xdg.enable = true;
        xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
      }
      config.${namespace}.home.extraOptions
    ];

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
