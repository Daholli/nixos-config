{
  options,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.tools.git;
  user = config.wyrdgard.user;
in {
  options.wyrdgard.tools.git = {
    enable = mkBoolOpt true "Enable Git (Default true)";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;
      lfs = enabled;
      extraConfig = {
        init = {defaultBranch = "main";};
	pull = {rebase = false;};
        push = {autoSetupRemote = true;};
      };
    };
  };
}
