{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps._1password;
in {
  options.wyrdgard.apps._1password = with types; {
    enable = mkBoolOpt false "Enable 1Password";
  };

  config = mkIf cfg.enable {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [config.wyrdgard.user.name];
      };
    };
  };
}
