{ options, config, lib, pkgs, ... }:

with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.submodules.socials;
in
{
  options.wyrdgard.submodules.socials = with types; {
    enable = mkBoolOpt false "Whether to enable a social apps";
  };


}
