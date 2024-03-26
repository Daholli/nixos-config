{ options, config, lib, pkgs, ... }:

with lib;
with lib.wyrdgard;

let
  cfg = config.wyrdgard.tools.nix-ld;
in
{
  options.wyrdgard.tools.nix-ld = with types; {
    enable = mkBoolOpt false "Wether or not to enable nix-ld";
  };

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;
  };
}
