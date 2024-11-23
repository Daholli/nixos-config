{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.user;
  defaultIconFileName = "profile.png";
in
{
  options.${namespace}.user = with types; {
    name = mkOpt str "cholli" "The name to use for the user account.";
    fullName = mkOpt str "Christoph Hollizeck" "The full name of the user.";
    email = mkOpt str "christoph.hollizeck@hey.com" "The email of the user.";
    initialPassword = mkOpt str "asdf" "The initial password to use when the user is first created.";
    icon = mkOpt (nullOr path) ./${defaultIconFileName} "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } (mdDoc "Extra options passed to `users.users.<name>`.");
    trustedPublicKeys = mkOption {
      default = [ ];
      type = nullOr (listOf str);
      description = "Trusted public keys for this user for the machine";
    };
  };

  config = {
    environment.systemPackages = [ ];

    # remove default nix alias
    environment.shellAliases = {
      l = null;
      ls = null;
      ll = null;
    };

    programs.fish = enabled;
    users.defaultUserShell = pkgs.fish;

    ${namespace}.home = {
      file = {
        "Desktop/.keep".text = "";
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "Videos/.keep".text = "";
        "projects/.keep".text = "";
        ".face".source = cfg.icon;
        "Pictures/${defaultIconFileName}".source = cfg.icon;
      };
    };

    users.users.${cfg.name} = {
      isNormalUser = true;

      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";

      # Arbitrary user ID to use for the user. Since I only
      # have a single user on my machines this won't ever collide.
      # However, if you add multiple users you'll need to change this
      # so each user has their own unique uid (or leave it out for the
      # system to select).
      uid = 1000;

      openssh.authorizedKeys.keys = cfg.trustedPublicKeys;

      extraGroups = [ "steamcmd" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}
