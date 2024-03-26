{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.fish;
in {
  options.wyrdgard.apps.cli-apps.fish = with types; {
    enable = mkBoolOpt false "Whether or not to enable the fish shell";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fish
      starship
      colorls
    ];
  };
}
