{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.apps.kitty;
in
{
  options.${namespace}.apps.kitty = {
    enable = mkEnableOption "Kitty";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kitty ];

    home.sessionVariables.TERMINAL = "kitty";

    # TODO: move this to a thunar specific module
    home.file.".config/Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
      	<icon>kitty</icon>
      	<name>Open Kitty here</name>
      	<submenu></submenu>
      	<unique-id>1726095927116900-1</unique-id>
      	<command>${pkgs.kitty}/bin/kitty %f</command>
      	<description>Example for a custom action</description>
      	<range></range>
      	<patterns>*</patterns>
      	<startup-notify/>
      	<directories/>
      </action>
      </actions>
    '';

    programs.kitty = {
      enable = true;
      # themeFile = "tokyo_night_night";
      font = {
        name = "Code New Roman";
        size = 15;
      };
      shellIntegration.enableFishIntegration = true;
      settings = {
        "background_opacity" = "0.90";
        "shell" = "fish";
        "confirm_os_window_close" = "0";
      };
    };
  };
}
