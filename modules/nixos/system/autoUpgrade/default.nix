{
  config,
  inputs,
  lib,
  namespace,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.autoUpgrade;
in
{
  options.${namespace}.system.autoUpgrade = with types; {
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
