{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;

  cfg = config.${namespace}.desktop.addons.hyprpanel;
  username = config.${namespace}.user.name;

in
{
  options.${namespace}.desktop.addons.hyprpanel = {
    enable = mkEnableOption "Enable HyprIdle";
  };

  config = mkIf cfg.enable {

    snowfallorg.users.${username}.home.config = {
      wayland.windowManager.hyprland.settings.exec-once = [
        "${pkgs.hyprpanel}/bin/hyprpanel"
      ];

      programs.hyprpanel = {
        enable = true;
        settings = {
          menus.dashboard.powermenu.avatar.image = "/home/cholli/Pictures/profile.png";

          bar = {
            launcher.autoDetectIcon = true;
            workspaces = {
              show_icons = false;
              show_numbered = true;
            };
            layouts = {
              "0" = {
                "left" = [
                  "dashboard"
                  "workspaces"
                ];
                "middle" = [
                  "windowtitle"
                ];
                "right" = [
                  "volume"
                  "bluetooth"
                  "cputemp"
                  "cpu"
                  "ram"
                  "systray"
                  "clock"
                  "notifications"
                ];
              };
              "1" = {
                "left" = [
                  "workspaces"
                ];
                "right" = [
                  "clock"
                ];
              };
            };
            customModules = {
              ram = {
                icon = " ";
                labelType = "used/total";
              };
              cpu = {
                icon = " ";
                leftClick = "kitty --hold btop";
              };
              cpuTemp = {
                sensor = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon2/temp3_input";
                unit = "metric";
                showUnit = true;

              };
            };
            clock.format = "%a %b %d  %H:%M:%S";
            notifications = {
              show_total = true;
              hideCountWhenZero = false;
            };
          };

          layouts = {
            "0" = {
              left = [
                "dashboard"
                "workspaces"
              ];
              middle = [ "windowtitle" ];
              right = [
                "volume"
                "bluetooth"
                "cputemp"
                "cpu"
                "ram"
                "systray"
                "clock"
                "notifications"
              ];
            };
            "1" = {
              left = [ "workspaces" ];
              right = [ "clock" ];
            };
          };
          theme = {
            bar = {
              floating = true;
              background = "#11111b";
              border.color = "#b4befe";
              buttons = {
                background = "#242438";
                battery.background = "#242438";
                battery.border = "#f9e2af";
                battery.icon = "#242438";
                battery.icon_background = "#f9e2af";
                battery.text = "#f9e2af";
                bluetooth.background = "#242438";
                bluetooth.border = "#89dceb";
                bluetooth.icon = "#1e1e2e";
                bluetooth.icon_background = "#89dbeb";
                bluetooth.text = "#89dceb";
                borderColor = "#b4befe";
                clock.background = "#242438";
                clock.border = "#f5c2e7";
                clock.icon = "#232338";
                clock.icon_background = "#f5c2e7";
                clock.text = "#f5c2e7";
                dashboard.background = "#f9e2af";
                dashboard.border = "#f9e2af";
                dashboard.icon = "#1e1e2e";
                hover = "#45475a";
                icon = "#242438";
                icon_background = "#b4befe";
                media.background = "#242438";
                media.border = "#b4befe";
                media.icon = "#1e1e2e";
                media.icon_background = "#b4befe";
                media.text = "#b4befe";
                modules.cava.background = "#242438";
                modules.cava.border = "#94e2d5";
                modules.cava.icon = "#242438";
                modules.cava.icon_background = "#94e2d5";
                modules.cava.text = "#94e2d5";
                modules.cpu.background = "#242438";
                modules.cpu.border = "#f38ba8";
                modules.cpu.icon = "#181825";
                modules.cpu.icon_background = "#f38ba8";
                modules.cpu.text = "#f38ba8";
                modules.hypridle.background = "#242438";
                modules.hypridle.border = "#f5c2e7";
                modules.hypridle.icon = "#242438";
                modules.hypridle.icon_background = "#f5c2e7";
                modules.hypridle.text = "#f5c2e7";
                modules.hyprsunset.background = "#242438";
                modules.hyprsunset.border = "#fab387";
                modules.hyprsunset.icon = "#242438";
                modules.hyprsunset.icon_background = "#fab387";
                modules.hyprsunset.text = "#fab387";
                modules.kbLayout.background = "#242438";
                modules.kbLayout.border = "#89dceb";
                modules.kbLayout.icon = "#181825";
                modules.kbLayout.icon_background = "#89dceb";
                modules.kbLayout.text = "#89dceb";
                modules.microphone.background = "#242438";
                modules.microphone.border = "#a6e3a1";
                modules.microphone.icon = "#242438";
                modules.microphone.icon_background = "#a6e3a1";
                modules.microphone.text = "#a6e3a1";
                modules.netstat.background = "#242438";
                modules.netstat.border = "#a6e3a1";
                modules.netstat.icon = "#181825";
                modules.netstat.icon_background = "#a6e3a1";
                modules.netstat.text = "#a6e3a1";
                modules.power.background = "#242438";
                modules.power.border = "#f38ba8";
                modules.power.icon = "#181825";
                modules.power.icon_background = "#f38ba8";
                modules.ram.background = "#242438";
                modules.ram.border = "#f9e2af";
                modules.ram.icon = "#181825";
                modules.ram.icon_background = "#f9e2af";
                modules.ram.text = "#f9e2af";
                modules.storage.background = "#242438";
                modules.storage.border = "#f5c2e7";
                modules.storage.icon = "#181825";
                modules.storage.icon_background = "#f5c2e7";
                modules.storage.text = "#f5c2e7";
                modules.submap.background = "#242438";
                modules.submap.border = "#94e2d5";
                modules.submap.icon = "#181825";
                modules.submap.icon_background = "#94e2d5";
                modules.submap.text = "#94e2d5";
                modules.updates.background = "#242438";
                modules.updates.border = "#cba6f7";
                modules.updates.icon = "#181825";
                modules.updates.icon_background = "#cba6f7";
                modules.updates.text = "#cba6f7";
                modules.weather.background = "#242438";
                modules.weather.border = "#b4befe";
                modules.weather.icon = "#242438";
                modules.weather.icon_background = "#b4befe";
                modules.weather.text = "#b4befe";
                modules.worldclock.background = "#242438";
                modules.worldclock.border = "#f5c2e7";
                modules.worldclock.icon = "#242438";
                modules.worldclock.icon_background = "#f5c2e7";
                modules.worldclock.text = "#f5c2e7";
                network.background = "#242438";
                network.border = "#cba6f7";
                network.icon = "#242438";
                network.icon_background = "#caa6f7";
                network.text = "#cba6f7";
                notifications.background = "#242438";
                notifications.border = "#b4befe";
                notifications.icon = "#1e1e2e";
                notifications.icon_background = "#b4befe";
                notifications.total = "#b4befe";
                style = "split";
                systray.background = "#242438";
                systray.border = "#b4befe";
                systray.customIcon = "#cdd6f4";
                text = "#b4befe";
                volume.background = "#242438";
                volume.border = "#eba0ac";
                volume.icon = "#242438";
                volume.icon_background = "#eba0ac";
                volume.text = "#eba0ac";
                windowtitle.background = "#242438";
                windowtitle.border = "#f5c2e7";
                windowtitle.icon = "#1e1e2e";
                windowtitle.icon_background = "#f5c2e7";
                windowtitle.text = "#f5c2e7";
                workspaces.active = "#f5c2e7";
                workspaces.available = "#89dceb";
                workspaces.background = "#242438";
                workspaces.border = "#f5c2e7";
                workspaces.hover = "#f5c2e7";
                workspaces.numbered_active_highlighted_text_color = "#181825";
                workspaces.numbered_active_underline_color = "#f5c2e7";
                workspaces.occupied = "#f2cdcd";
                y_margins = "0.2em";
              };
              menus = {
                background = "#11111b";
                border.color = "#313244";
                buttons.active = "#f5c2e6";
                buttons.default = "#b4befe";
                buttons.disabled = "#585b71";
                buttons.text = "#181824";
                cards = "#1e1e2e";
                check_radio_button.active = "#b4beff";
                check_radio_button.background = "#45475a";
                dimtext = "#585b70";
                dropdownmenu.background = "#11111b";
                dropdownmenu.divider = "#1e1e2e";
                dropdownmenu.text = "#cdd6f4";
                feinttext = "#313244";
                iconbuttons.active = "#b4beff";
                iconbuttons.passive = "#cdd6f3";
                icons.active = "#b4befe";
                icons.passive = "#585b70";
                label = "#b4befe";
                listitems.active = "#b4befd";
                listitems.passive = "#cdd6f4";
                menu = {
                  battery.background.color = "#11111b";
                  battery.border.color = "#313244";
                  battery.card.color = "#1e1e2e";
                  battery.icons.active = "#f9e2af";
                  battery.icons.passive = "#9399b2";
                  battery.label.color = "#f9e2af";
                  battery.listitems.active = "#f9e2af";
                  battery.listitems.passive = "#cdd6f3";
                  battery.slider.background = "#585b71";
                  battery.slider.backgroundhover = "#45475a";
                  battery.slider.primary = "#f9e2af";
                  battery.slider.puck = "#6c7086";
                  battery.text = "#cdd6f4";
                  bluetooth.background.color = "#11111b";
                  bluetooth.border.color = "#313244";
                  bluetooth.card.color = "#1e1e2e";
                  bluetooth.iconbutton.active = "#89dceb";
                  bluetooth.iconbutton.passive = "#cdd6f4";
                  bluetooth.icons.active = "#89dceb";
                  bluetooth.icons.passive = "#9399b2";
                  bluetooth.label.color = "#89dceb";
                  bluetooth.listitems.active = "#89dcea";
                  bluetooth.listitems.passive = "#cdd6f4";
                  bluetooth.scroller.color = "#89dceb";
                  bluetooth.status = "#6c7086";
                  bluetooth.switch.disabled = "#313245";
                  bluetooth.switch.enabled = "#89dceb";
                  bluetooth.switch.puck = "#454759";
                  bluetooth.switch_divider = "#45475a";
                  bluetooth.text = "#cdd6f4";
                  clock.background.color = "#11111b";
                  clock.border.color = "#313244";
                  clock.calendar.contextdays = "#585b70";
                  clock.calendar.currentday = "#f5c2e7";
                  clock.calendar.days = "#cdd6f4";
                  clock.calendar.paginator = "#f5c2e6";
                  clock.calendar.weekdays = "#f5c2e7";
                  clock.calendar.yearmonth = "#94e2d5";
                  clock.card.color = "#1e1e2e";
                  clock.text = "#cdd6f4";
                  clock.time.time = "#f5c2e7";
                  clock.time.timeperiod = "#94e2d5";
                  clock.weather.hourly.icon = "#f5c2e7";
                  clock.weather.hourly.temperature = "#f5c2e7";
                  clock.weather.hourly.time = "#f5c2e7";
                  clock.weather.icon = "#f5c2e7";
                  clock.weather.stats = "#f5c2e7";
                  clock.weather.status = "#94e2d5";
                  clock.weather.temperature = "#cdd6f4";
                  clock.weather.thermometer.cold = "#89b4fa";
                  clock.weather.thermometer.extremelycold = "#89dceb";
                  clock.weather.thermometer.extremelyhot = "#f38ba8";
                  clock.weather.thermometer.hot = "#fab387";
                  clock.weather.thermometer.moderate = "#b4befe";
                  dashboard.background.color = "#11111b";
                  dashboard.border.color = "#313244";
                  dashboard.card.color = "#1e1e2e";
                  dashboard.controls.bluetooth.background = "#89dceb";
                  dashboard.controls.bluetooth.text = "#181824";
                  dashboard.controls.disabled = "#585b70";
                  dashboard.controls.input.background = "#f5c2e7";
                  dashboard.controls.input.text = "#181824";
                  dashboard.controls.notifications.background = "#f9e2af";
                  dashboard.controls.notifications.text = "#181824";
                  dashboard.controls.volume.background = "#eba0ac";
                  dashboard.controls.volume.text = "#181824";
                  dashboard.controls.wifi.background = "#cba6f7";
                  dashboard.controls.wifi.text = "#181824";
                  dashboard.directories.left.bottom.color = "#eba0ac";
                  dashboard.directories.left.middle.color = "#f9e2af";
                  dashboard.directories.left.top.color = "#f5c2e7";
                  dashboard.directories.right.bottom.color = "#b4befe";
                  dashboard.directories.right.middle.color = "#cba6f7";
                  dashboard.directories.right.top.color = "#94e2d5";
                  dashboard.monitors.bar_background = "#45475a";
                  dashboard.monitors.cpu.bar = "#eba0ad";
                  dashboard.monitors.cpu.icon = "#eba0ac";
                  dashboard.monitors.cpu.label = "#eba0ac";
                  dashboard.monitors.disk.bar = "#f5c2e8";
                  dashboard.monitors.disk.icon = "#f5c2e7";
                  dashboard.monitors.disk.label = "#f5c2e7";
                  dashboard.monitors.gpu.bar = "#a6e3a2";
                  dashboard.monitors.gpu.icon = "#a6e3a1";
                  dashboard.monitors.gpu.label = "#a6e3a1";
                  dashboard.monitors.ram.bar = "#f9e2ae";
                  dashboard.monitors.ram.icon = "#f9e2af";
                  dashboard.monitors.ram.label = "#f9e2af";
                  dashboard.powermenu.confirmation.background = "#11111b";
                  dashboard.powermenu.confirmation.body = "#cdd6f4";
                  dashboard.powermenu.confirmation.border = "#313244";
                  dashboard.powermenu.confirmation.button_text = "#11111a";
                  dashboard.powermenu.confirmation.card = "#1e1e2e";
                  dashboard.powermenu.confirmation.confirm = "#a6e3a1";
                  dashboard.powermenu.confirmation.deny = "#f38ba8";
                  dashboard.powermenu.confirmation.label = "#b4befe";
                  dashboard.powermenu.logout = "#a6e3a1";
                  dashboard.powermenu.restart = "#fab387";
                  dashboard.powermenu.shutdown = "#f38ba8";
                  dashboard.powermenu.sleep = "#89dceb";
                  dashboard.profile.name = "#f5c2e7";
                  dashboard.shortcuts.background = "#b4befe";
                  dashboard.shortcuts.recording = "#a6e3a1";
                  dashboard.shortcuts.text = "#181824";
                  media.album = "#f5c2e8";
                  media.artist = "#94e2d6";
                  media.background.color = "#11111b";
                  media.border.color = "#313244";
                  media.buttons.background = "#b4beff";
                  media.buttons.enabled = "#94e2d4";
                  media.buttons.inactive = "#585b70";
                  media.buttons.text = "#11111b";
                  media.card.color = "#1e1e2e";
                  media.slider.background = "#585b71";
                  media.slider.backgroundhover = "#45475a";
                  media.slider.primary = "#f5c2e7";
                  media.slider.puck = "#6c7086";
                  media.song = "#b4beff";
                  media.timestamp = "#cdd6f4";
                  network.background.color = "#11111b";
                  network.border.color = "#313244";
                  network.card.color = "#1e1e2e";
                  network.iconbuttons.active = "#cba6f7";
                  network.iconbuttons.passive = "#cdd6f4";
                  network.icons.active = "#cba6f7";
                  network.icons.passive = "#9399b2";
                  network.label.color = "#cba6f7";
                  network.listitems.active = "#cba6f6";
                  network.listitems.passive = "#cdd6f4";
                  network.scroller.color = "#cba6f7";
                  network.status.color = "#6c7086";
                  network.switch.disabled = "#313245";
                  network.switch.enabled = "#cba6f7";
                  network.switch.puck = "#454759";
                  network.text = "#cdd6f4";
                  notifications.background = "#11111b";
                  notifications.border = "#313244";
                  notifications.card = "#1e1e2e";
                  notifications.clear = "#f38ba8";
                  notifications.label = "#b4befe";
                  notifications.no_notifications_label = "#313244";
                  notifications.pager.background = "#11111b";
                  notifications.pager.button = "#b4befe";
                  notifications.pager.label = "#9399b2";
                  notifications.scrollbar.color = "#b4befe";
                  notifications.switch.disabled = "#313245";
                  notifications.switch.enabled = "#b4befe";
                  notifications.switch.puck = "#454759";
                  notifications.switch_divider = "#45475a";
                  power.background.color = "#11111b";
                  power.border.color = "#313244";
                  power.buttons.logout.background = "#1e1e2e";
                  power.buttons.logout.icon = "#181824";
                  power.buttons.logout.icon_background = "#a6e3a1";
                  power.buttons.logout.text = "#a6e3a1";
                  power.buttons.restart.background = "#1e1e2e";
                  power.buttons.restart.icon = "#181824";
                  power.buttons.restart.icon_background = "#fab387";
                  power.buttons.restart.text = "#fab387";
                  power.buttons.shutdown.background = "#1e1e2e";
                  power.buttons.shutdown.icon = "#181824";
                  power.buttons.shutdown.icon_background = "#f38ba7";
                  power.buttons.shutdown.text = "#f38ba8";
                  power.buttons.sleep.background = "#1e1e2e";
                  power.buttons.sleep.icon = "#181824";
                  power.buttons.sleep.icon_background = "#89dceb";
                  power.buttons.sleep.text = "#89dceb";
                  systray.dropdownmenu.background = "#11111b";
                  systray.dropdownmenu.divider = "#1e1e2e";
                  systray.dropdownmenu.text = "#cdd6f4";
                  volume.audio_slider.background = "#585b71";
                  volume.audio_slider.backgroundhover = "#45475a";
                  volume.audio_slider.primary = "#eba0ac";
                  volume.audio_slider.puck = "#585b70";
                  volume.background.color = "#11111b";
                  volume.border.color = "#313244";
                  volume.card.color = "#1e1e2e";
                  volume.iconbutton.active = "#eba0ac";
                  volume.iconbutton.passive = "#cdd6f4";
                  volume.icons.active = "#eba0ac";
                  volume.icons.passive = "#9399b2";
                  volume.input_slider.background = "#585b71";
                  volume.input_slider.backgroundhover = "#45475a";
                  volume.input_slider.primary = "#eba0ac";
                  volume.input_slider.puck = "#585b70";
                  volume.label.color = "#eba0ac";
                  volume.listitems.active = "#eba0ab";
                  volume.listitems.passive = "#cdd6f4";
                  volume.text = "#cdd6f4";
                };
                popover.background = "#181824";
                popover.border = "#181824";
                popover.text = "#b4befe";
                progressbar.background = "#45475a";
                progressbar.foreground = "#b4befe";
                slider.background = "#585b71";
                slider.backgroundhover = "#45475a";
                slider.primary = "#b4befe";
                slider.puck = "#6c7086";
                switch.disabled = "#313245";
                switch.enabled = "#b4befe";
                switch.puck = "#454759";
                text = "#cdd6f4";
                tooltip.background = "#11111b";
                tooltip.text = "#cdd6f4";
              };
              outer_spacing = "0.0em";
              transparent = true;

            };
            notification.actions.background = "#b4befd";
            notification.actions.text = "#181825";
            notification.background = "#181826";
            notification.border = "#313243";
            notification.close_button.background = "#f38ba7";
            notification.close_button.label = "#11111b";
            notification.label = "#b4befe";
            notification.labelicon = "#b4befe";
            notification.text = "#cdd6f4";
            notification.time = "#7f849b";
            osd.bar_color = "#b4beff";
            osd.bar_container = "#11111b";
            osd.bar_empty_color = "#313244";
            osd.bar_overflow_color = "#f38ba7";
            osd.icon = "#11111b";
            osd.icon_container = "#b4beff";
            osd.label = "#b4beff";

          };
        };
      };
    };

  };
}
