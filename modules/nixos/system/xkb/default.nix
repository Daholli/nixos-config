{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.system.xkb;
in {
  options.wyrdgard.system.xkb = with types; {
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
