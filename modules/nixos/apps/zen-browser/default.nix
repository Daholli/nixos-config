{
  config,
  lib,
  pkgs,
  system,
  inputs,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.wyrdgard.apps.zen-browser;

  zenbrowser = inputs.zen-browser.packages."${system}".default;
in
{
  options.wyrdgard.apps.zen-browser = {
    enable = mkEnableOption "Whether or not to enable zen browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      zenbrowser
    ];

    environment.sessionVariables.DEFAULT_BROWSER = "${zenbrowser}/bin/zen";

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
