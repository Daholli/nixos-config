{
  flake.modules.homeManager.cholli =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    {

      config = lib.mkIf osConfig.programs.niri.enable {
        programs.waybar = {
          enable = true;
          style = ./waybar.css;
          settings = {
            topBar = {
              layer = "top";
              position = "top";
              output = "DP-1";
              height = 30;
              spacing = 2;
              modules-left = [ "niri/workspaces" ];
              modules-center = [ "clock" ];
              modules-right = [
                "idle_inhibitor"
                "bluetooth"
                "wireplumber"
                "cpu"
                "memory"
                "tray"
              ];
              "niri/workspaces" = {
                "format" = "<span size='larger'>{icon}</span>";
                "on-click" = "activate";
                "format-icons" = {
                  "active" = "";
                  "default" = "";
                };
                "icon-size" = 10;
                "sort-by-number" = true;
              };
              "clock" = {
                "format" = "{:%d.%m.%Y | %H:%M}";
              };
              "wireplumber" = {
                "format" = " {volume}%";
                "on-click" = "${lib.getExe pkgs.pavucontrol}";
                "max-volume" = 100;
                "scroll-step" = 5;
              };
              "cpu" = {
                "format" = " {usage}%";
                "on-click" = "${lib.getExe pkgs.kitty} ${lib.getExe pkgs.btop}";
              };
              "memory" = {
                "interval" = 30;
                "format" = " {used:0.1f}G ";
              };
              "bluetooth" = {
                "format" = "";
                "on-click" = "${lib.getExe pkgs.kitty} ${lib.getExe pkgs.bluetui}";
                "format-disabled" = "󰂲";
                "format-connected" = "󰂱";
                "tooltip-format" = "{controller_alias}\t{controller_address}";
                "tooltip-format-connected" = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
                "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
              };
              "tray" = {
                "icon-size" = 16;
                "spacing" = 16;
              };
              "idle_inhibitor" = {
                "format" = "{icon}";
                "format-icons" = {
                  "activated" = "";
                  "deactivated" = "󰒲";
                };
              };
            };
          };
        };
      };
    };
}
