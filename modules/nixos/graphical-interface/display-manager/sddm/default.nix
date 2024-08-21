{ config, lib, ... }:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.graphical-interface.display-manager.sddm;
in
{
  options.wyrdgard.graphical-interface.display-manager.sddm = with types; {
    enable = mkEnableOption "Whether to enable a sddm";
  };

  config = mkIf cfg.enable {
    services = {
      xserver = enabled;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
    };
  };
}
