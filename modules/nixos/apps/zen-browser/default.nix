{
  options,
  config,
  lib,
  pkgs,
  system,
  inputs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.zen-browser;
in
{
  options.wyrdgard.apps.zen-browser = with types; {
    enable = mkBoolOpt false "Whether or not to enable zen browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.zen-browser.packages."${system}".default
    ];

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          .zen-wrapped
        '';
        mode = "0755";
      };
    };
  };
}
