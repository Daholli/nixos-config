{
  config,
  lib,
  namespace,
  options,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{
  options.${namespace}.tools.git = with types; {
    enable = mkBoolOpt true "Wether or not to enable git (Default enabled)";
    userName = mkOpt types.str user.fullName "The name to use git with";
    userEmail = mkOpt types.str user.email "The email to use git with";
    signingKey = mkOpt types.str "ACCFA2DB47795D9E" "The key ID to sign commits with.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gitAndTools.gh
      # gitbutler
    ];

    ${namespace}.home.extraOptions = {
      programs.git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs.enable = true;
        signing = {
          key = cfg.signingKey;
          signByDefault = true;
        };
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = true;
          };
          push = {
            autoSetupRemote = true;
          };
          safe = {
            directory = "${config.users.users.${user.name}.home}/projects/config";
          };
          lfs."https://git.christophhollizeck.dev/Daholli/nixos-config.git/info/lfs".locksverify = true;
        };
      };
    };
  };
}
