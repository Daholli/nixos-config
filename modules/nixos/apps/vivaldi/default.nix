{
  config,
  lib,
  namespace,
  pkgs,
  options,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.apps.vivaldi;
in
{
  options.${namespace}.apps.vivaldi = with types; {
    enable = mkBoolOpt false "Whether or not to enable vivaldi browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vivaldi
      vivaldi-ffmpeg-codecs
      qt5.qtwayland
    ];

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivaldi-bin
        '';
        mode = "0755";
      };
    };

    # environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
