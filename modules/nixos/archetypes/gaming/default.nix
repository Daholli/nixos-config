{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.archetypes.gaming;
in {
  options.wyrdgard.archetypes.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gaming archetype.";
  };

  config = mkIf cfg.enable {
    wyrdgard.submodules = {
      basics = enabled;
      graphical-interface = enabled;
      games = enabled;
      socials = enabled;
    };
  };
}
