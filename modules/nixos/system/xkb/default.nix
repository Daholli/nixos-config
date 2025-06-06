{
  config,
  lib,
  namespace,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.xkb;
in
{
  options.${namespace}.system.xkb = with types; {
    enable = mkBoolOpt false "Whether or not to configure xkb.";
  };

  config = mkIf cfg.enable {
    console.useXkbConfig = true;
    services.xserver = {
      xkb.layout = "us";
      xkb.variant = "";
      xkb.options = "caps:escape";
    };
  };
}
