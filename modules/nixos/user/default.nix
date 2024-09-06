{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.user;
  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = {
      fileName = defaultIconFileName;
    };
  };
  propagatedIcon =
    pkgs.runCommandNoCC "propagated-icon"
      {
        passthru = {
          inherit (fileName) ;
        };
      }
      ''
        local target="$out/share/wyrdgard-icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.wyrdgard.user = with types; {
    name = mkOpt str "cholli" "The name to use for the user account.";
    fullName = mkOpt str "Christoph Hollizeck" "The full name of the user.";
    email = mkOpt str "christoph.hollizeck@hey.com" "The email of the user.";
    initialPassword = mkOpt str "asdf" "The initial password to use when the user is first created.";
    icon = mkOpt (nullOr package) defaultIcon "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } (mdDoc "Extra options passed to `users.users.<name>`.");
  };

  config = {
    environment.systemPackages = with pkgs; [ ];

    programs.fish = enabled;
    users.defaultUserShell = pkgs.fish;

    wyrdgard.home = {
      file = {
        "Desktop/.keep".text = "";
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "Videos/.keep".text = "";
        "projects/.keep".text = "";
        ".face".source = cfg.icon;
        "Pictures/${cfg.icon.fileName or (builtins.baseNameOf cfg.icon)}".source = cfg.icon;
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

      extraGroups = [ "steamcmd" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}
