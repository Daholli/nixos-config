{
  lib,
  config,
  pkgs,
  osConfig ? {},
  ...
}: let
  inherit (lib) types mkIf mkDefault mkMerge;
  inherit (lib.wyrdgard) mkOpt;

  cfg = config.wyrdgard.user;

  is-linux = pkgs.stdenv.isLinux;
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null
    then null
    else if is-darwin
    then "/Users/${cfg.name}"
    else "/home/${cfg.name}";
in {
  options.wyrdgard.user = {
    enable = mkOpt types.bool true "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) (config.snowfallorg.user.name or "cholli") "The user account.";

    fullName = mkOpt types.str "Christoph Hollizeck" "The full name of the user.";
    email = mkOpt types.str "christoph.hollizeck@hey.com" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "wyrdgard.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "wyrdgard.user.home must be set";
        }
      ];

      home = {
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
      };
    }
  ]);
}
