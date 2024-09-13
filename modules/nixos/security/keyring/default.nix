{
  options,
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.security.keyring;
in
{
  options.${namespace}.security.keyring = with types; {
    enable = mkBoolOpt true "Whether to enable gnome keyring.";
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true; 
  };
}
