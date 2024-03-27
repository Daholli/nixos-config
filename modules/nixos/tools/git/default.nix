{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.tools.git;
  user = config.wyrdgard.user;
in {
  options.wyrdgard.tools.git = with types; {
    enable = mkBoolOpt true "Wether or not to enable git (Default enabled)";
    userName = mkOpt types.str user.fullName "The name to use git with";
    userEmail = mkOpt types.str user.email "The email to use git with";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gitAndTools.gh
    ];

    programs.git = {
      enable = true;
      lfs.enable = true;
      config = {
        init = {defaultBranch = "main";};
	pull = {rebase = false;};
        push = {autoSetupRemote = true;};
      };
    };
  };
}
