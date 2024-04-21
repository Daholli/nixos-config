{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.submodules.graphical-interface;
in
{
  options.wyrdgard.submodules.graphical-interface = with types; {
    enable = mkBoolOpt false "Whether to enable a graphical interface";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ xdg-utils ];

    services = {
      xserver = {
        enable = true;
      };
      displayManager = {
        defaultSession = "plasmax11";
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      desktopManager.plasma6 = enabled;
    };
  };
}
