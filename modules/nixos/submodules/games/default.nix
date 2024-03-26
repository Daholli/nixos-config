{ options, config, lib, pkgs, ... }:

with lib;
with lib.wyrdgard;

let cfg = config.wyrdgard.submodules.games;
in
{
  options.wyrdgard.submodules.games = with types; {
    enable = mkBoolOpt false "Whether or not you want to enable non steam games such as minecraft";
  };

  config = mkIf cfg.enable { };

}
