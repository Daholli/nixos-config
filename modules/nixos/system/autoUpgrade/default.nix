{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.system.autoUpgrade;
in
{
  options.wyrdgard.system.autoUpgrade = with types; {
    enable = mkEnableOption "Enable auto-upgrade";
    time = mkOpt str "02:00" "Time to run auto-upgrade";
  };

  config = mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--update-input"
        "nixpkgs"
        "--print-build-logs"
      ];
      dates = cfg.time;
      randomizedDelaySec = "45min";
    };
  };
}
