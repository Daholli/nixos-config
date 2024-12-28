{
  config,
  lib,
  namespace,
  options,
  ...
}:
with lib.${namespace};
let
  inherit (lib) mkIf types;
  cfg = config.${namespace}.tools.git;
  user = config.${namespace}.user;
in
{
  options.${namespace}.tools.git = {
    enable = mkBoolOpt true "Enable Git (Default true)";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    signingKey = mkOpt types.str "ACCFA2DB47795D9E" "The pub key to sign commits with.";
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
        core = {
          fsmonitor = true;
        };
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
          directory = "${user.home}/projects/config";
        };
        maintenance = {
          repo = [
            "${user.home}/projects/nixpkgs"
            "${user.home}/projects/config"
          ];
          strategy = "incremental";
        };
        lfs."https://git.christophhollizeck.dev/Daholli/nixos-config.git/info/lfs".locksverify = true;
      };
    };
  };
}
