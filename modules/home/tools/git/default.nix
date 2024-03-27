{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.wyrdgard) mkOpt enabled;

  cfg = config.wyrdgard.tools.git;
  user = config.wyrdgard.user;
in {
  options.wyrdgard.tools.git = {
    enable = mkEnableOption "Git";
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
        push = {autoSetupRemote = true;};
      };
    };
  };
}
