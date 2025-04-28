{
  config,
  inputs,
  lib,
  namespace,
  system,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.apps.zen-browser;

  zenbrowser = inputs.zen-browser.packages."${system}".default;
in
{
  options.${namespace}.apps.zen-browser = {
    enable = mkEnableOption "Whether or not to enable zen browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      zenbrowser
    ];

    environment.sessionVariables = {
      DEFAULT_BROWSER = "${zenbrowser}/bin/zen-beta";
      BROWSER = "zen-beta";
    };

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen
        '';
        mode = "0755";
      };
    };
  };
}
