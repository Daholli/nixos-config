{ options, config, lib, pkgs, ... }:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.submodules.games;
in
{
  options.wyrdgard.submodules.games = with types; {
    enable = mkBoolOpt false "Whether or not you want to enable steam and other games";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
    			prismlauncher
    		];
    
    wyrdgard = {
      apps = {
        steam = enabled;
      };
    };

  };

}
