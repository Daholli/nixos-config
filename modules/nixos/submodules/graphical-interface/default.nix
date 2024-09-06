{
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

    wyrdgard.graphical-interface = {
      display-manager.sddm = enabled;
      desktop-manager = {
        kde = enabled;
      };
    };
  };
}
