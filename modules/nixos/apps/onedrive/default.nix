{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.onedrive;
in
{
  options.wyrdgard.apps.onedrive = with types; {
    enable = mkEnableOption "Enable OneDrive integration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ onedrivegui ];

    services.onedrive = {
      enable = true;
    };
  };
}
