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
  cfg = config.wyrdgard.security.sops;
in
{
  options.wyrdgard.security.sops = with types; {
    enable = mkBoolOpt true "Enable sops (Default true)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFile = ../../../../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      age.keyFile = "/home/cholli/.config/sops/age/keys.txt";
    };
  };
}
