{
  lib,
  config,
  ...
}:

let
  cfg = config.wyrdgard.services.onedrive;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.wyrdgard.services.onedrive = {
    enable = mkEnableOption "Enable OneDrive integration";
  };

  config = mkIf cfg.enable {
    services.onedrive = {
      enable = true;
    };
  };
}
