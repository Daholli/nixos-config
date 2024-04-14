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
in
{
  options.wyrdgard.tools.git = with types; {
    enable = mkBoolOpt true "Wether or not to enable git (Default enabled)";
    userName = mkOpt types.str user.fullName "The name to use git with";
    userEmail = mkOpt types.str user.email "The email to use git with";
    signingKey =
      mkOpt types.str "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4iH29edivUi+k94apb6pasWq8qphfhYo0d6B2GhISf"
        "The key ID to sign commits with.";
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
          signByDefault = mkIf _1password.enable true;
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
          gpg = {
            format = "ssh";
            "ssh".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          };
        };
      };
    };
  };
}
