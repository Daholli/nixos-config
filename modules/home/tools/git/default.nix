{
  options,
  lib,
  config,
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
  options.wyrdgard.tools.git = {
    enable = mkBoolOpt true "Enable Git (Default true)";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey =
      mkOpt types.str "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN4iH29edivUi+k94apb6pasWq8qphfhYo0d6B2GhISf"
        "The pub key to sign commits with.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;
      signing = {
        key = cfg.signingKey;
        inherit (cfg) signByDefault;
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
          directory = "${user.home}/projects/config";
        };
        gpg = {
          format = "ssh";
          "ssh".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        };
      };
    };
  };
}
