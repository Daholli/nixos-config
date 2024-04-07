{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.tools.git;
  user = config.wyrdgard.user;
  gpg = config.wyrdgard.security.gpg;
in
{
  options.wyrdgard.tools.git = with types; {
    enable = mkBoolOpt true "Wether or not to enable git (Default enabled)";
    userName = mkOpt types.str user.fullName "The name to use git with";
    userEmail = mkOpt types.str user.email "The email to use git with";
    signingKey = mkOpt types.str "A8185688CDE3921F" "The key ID to sign commits with.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gitAndTools.gh
    ];

    wyrdgard.home.extraOptions = {
      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs.enable = true;
        signing = {
          key = cfg.signingKey;
          signByDefault = mkIf gpg.enable true;
        };
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = false;
          };
          push = {
            autoSetupRemote = true;
          };
          safe = {
            directory = "${config.users.users.${user.name}.home}/projects/config";
          };
        };
      };
    };
  };
}
