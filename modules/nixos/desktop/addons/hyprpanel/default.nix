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
    mkMerge
    mkOption
    literalExpression
    ;

  cfg = config.${namespace}.desktop.addons.hyprpanel;
  username = config.${namespace}.user.name;

  settingsFormat = pkgs.formats.json { };

  iconColor = "#242438";

  light-cyan = "#73daca";
  lightBlue = "#414868";
  medium-blue = "#9aa5ce";
  cyan-blue = "#7dcfff";
  navy-blue = "#24283b";
  dark-blue = "#1a1b26";
  dark-blue-gray = "565f89";
  dark-blue-yankees = "#272a3d";
  blue-magenta = "#181825";

  lightPurple = "#bb9af7";

  lightRed = "#f7768e";
  red = "#c0caf5";

  lightGreen = "#9ece6a";
  yellow = "#e0af68";

  settings = {
    tear = true;
    scalingPriority = "hyprland";
    font.name = "CodeNewRoman Nerd Font Mono";

    bar = {
      customModules = {
        updates.pollingInterval = 1440000;
        ram = {
          labelType = "used/total";
          icon = " ";
        };
        cpu = {
          label = true;
          leftClick = "kitty --hold btop";
          icon = " ";
        };
      };
      layouts = {
        "0" = {
          left = [
            "workspaces"
          ];
          middle = [
            "windowtitle"
          ];
          right = [
            "clock"
          ];
        };
        "1" = {
          left = [
            "dashboard"
            "workspaces"
          ];
          middle = [
            "windowtitle"
          ];
          right = [
            "volume"
            "bluetooth"
            "battery"
            "systray"
            "cpu"
            "ram"
            "clock"
            "notifications"
          ];
        };
      };
      workspaces = {
        showAllActive = true;
        show_icons = false;
        numbered_active_indicator = "underline";
        show_numbered = true;
        showWsIcons = false;
        showApplicationIcons = false;
        hideUnoccupied = true;
      };
      launcher = {
        icon = "󱄅";
        rightClick = "hyprpanel -t settings-dialog";
      };
      scrollSpeed = 0;
      windowtitle = {
        class_name = false;
        custom_title = false;
        icon = false;
        label = true;
        title_map = [

        ];
        truncation = true;
      };
      network = {
        label = false;
        truncation = false;
      };
      clock.format = "%a %b %d  %H:%M:%S";
      notifications.show_total = true;
    };

    menus = {
      clock.time.military = true;
      dashboard = {
        powermenu.avatar.image = "/home/cholli/Pictures/profile.png";

        shortcuts.enabled = false;
        directories.left = {
          directory1.command = "kitty $HOME/Downloads";
          directory3.command = "kitty $HOME/projects";
        };

        stats = {
          enable_gpu = true;
          enabled = false;
        };
        controls.enabled = false;
      };
      bluetooth = {
        showBattery = true;
        batteryState = "always";
      };
      transition = "crossfade";
    };

    theme = {
      bar = {
        floating = true;
        outer_spacing = "0.2em";
        buttons = {
          enableBorders = true;

          workspaces = {
            enableBorder = false;
            fontSize = "1.2em";
            smartHighlight = false;
            active = "#f7768e";
            occupied = "#f7768e";
            available = "#7dcfff";
            hover = "#f7768e";
            background = "#272a3d";
            numbered_active_highlighted_text_color = "#181825";
            numbered_active_underline_color = "#c678dd";
            border = "#f7768e";
          };
          modules = {
            power = {
              icon = "#181825";
              icon_background = "#f7768e";
              background = "#272a3d";
              border = "#f7768e";
            };
            ram = {
              enableBorder = false;
              spacing = "0.45em";
              icon = "#181825";
              icon_background = "#e0af68";
              text = "#e0af68";
              background = "#272a3d";
              border = "#e0af68";
            };
            cpu = {
              enableBorder = false;
              background = "#272a3d";
              icon = "#181825";
              icon_background = "#f7768e";
              text = "#f7768e";
              border = "#f7768e";
            };
            submap = {
              background = "#272a3d";
              text = "#73daca";
              border = "#73daca";
              icon = "#181825";
              icon_background = "#73daca";
            };
          };

          style = "split";
          icon = "#242438";
          icon_background = "#bb9af7";
          text = "#bb9af7";
          hover = "#414868";
          background = "#272a3d";
          dashboard = {
            enableBorder = false;
            icon = "#272a3d";
            background = "#e0af68";
            border = "#e0af68";
          };
          volume = {
            icon = "#272a3d";
            text = "#f7768e";
            background = "#272a3d";
            icon_background = "#f7768e";
            border = "#f7768e";
          };
          notifications = {
            total = "#bb9af7";
            icon = "#272a3d";
            background = "#272a3d";
            icon_background = "#bb9af7";
            border = "#bb9af7";
          };
          clock = {
            icon = "#272a3d";
            text = "#f7768e";
            background = "#272a3d";
            icon_background = "#f7768e";
            border = "#f7768e";
          };
          systray = {
            background = "#272a3d";
            border = "#414868";
            customIcon = "#c0caf5";
          };
          bluetooth = {
            icon = "#272a3d";
            text = "#7dcfff";
            background = "#272a3d";
            icon_background = "#7dcfff";
            border = "#7dcfff";
          };
          windowtitle = {
            icon = "#272a3d";
            text = "#f7768e";
            background = "#272a3d";
            icon_background = "#f7768e";
            border = "#f7768e";
            enableBorder = false;
          };
          radius = "0.3em";
          borderSize = "0.0em";
          padding_x = "0.7rem";
          padding_y = "0.2rem";
        };

        menus = {
          monochrome = false;
          opacity = 95;
          menu = {
            dashboard = {
              powermenu = {
                shutdown = "#f7768e";
                confirmation = {
                  deny = "#f7768e";
                  confirm = "#9ece6a";
                  button_text = "#1a1b26";
                  body = "#c0caf5";
                  label = "#bb9af7";
                  border = "#414868";
                  background = "#1a1b26";
                  card = "#24283b";
                };
                sleep = "#7dcfff";
                logout = "#9ece6a";
                restart = "#e0af68";
              };
              monitors = {
                ram = {
                  label = "#e0af68";
                  bar = "#e0af68";
                  icon = "#e0af68";
                };
                cpu = {
                  label = "#f7768e";
                  bar = "#f7768e";
                  icon = "#f7768e";
                };
                bar_background = "#414868";
              };
              directories = {
                right = {
                  bottom.color = "#bb9af7";
                  middle.color = "#bb9af7";
                  top.color = "#73daca";
                };
                left = {
                  bottom.color = "#f7768e";
                  middle.color = "#e0af68";
                  top.color = "#f7768e";
                };
              };
              controls = {
                input = {
                  text = "#1a1b26";
                  background = "#f7768e";
                };
                volume = {
                  text = "#1a1b26";
                  background = "#f7768e";
                };
                notifications = {
                  text = "#1a1b26";
                  background = "#e0af68";
                };
                bluetooth = {
                  text = "#1a1b26";
                  background = "#7dcfff";
                };
                disabled = "#414868";
              };
              profile.name = "#f7768e";
              border.color = "#414868";
              background.color = "#1a1b26";
              card.color = "#24283b";
            };
            notifications = {
              switch = {
                puck = "#565f89";
                disabled = "#565f89";
                enabled = "#bb9af7";
              };
              clear = "#f7768e";
              switch_divider = "#414868";
              border = "#414868";
              card = "#24283b";
              background = "#1a1b26";
              no_notifications_label = "#414868";
              label = "#bb9af7";
              scrollbar.color = "#bb9af7";
              pager = {
                button = "#bb9af7";
                label = "#565f89";
                background = "#1a1b26";
              };
            };
            clock = {
              text = "#c0caf5";
              border.color = "#414868";
              background.color = "#1a1b26";
              card.color = "#24283b";

              calendar = {
                contextdays = "#414868";
                days = "#c0caf5";
                currentday = "#f7768e";
                paginator = "#f7768e";
                weekdays = "#f7768e";
                yearmonth = "#73daca";
              };
              time = {
                timeperiod = "#73daca";
                time = "#f7768e";
              };
            };
            systray = {
              dropdownmenu.divider = "#24283b";
              dropdownmenu.text = "#c0caf5";
              dropdownmenu.background = "#1a1b26";
            };
            bluetooth = {
              iconbutton = {
                active = "#7dcfff";
                passive = "#c0caf5";
              };
              icons = {
                active = "#7dcfff";
                passive = "#565f89";
              };
              listitems = {
                active = "#7dcfff";
                passive = "#c0caf5";
              };
              switch = {
                puck = "#565f89";
                disabled = "#565f89";
                enabled = "#7dcfff";
              };
              switch_divider = "#414868";
              status = "#565f89";
              text = "#c0caf5";
              label.color = "#7dcfff";
              border.color = "#414868";
              background.color = "#1a1b26";
              card.color = "#24283b";
            };
            volume = {
              text = "#c0caf5";
              card.color = "#24283b";
              label.color = "#f7768e";
              input_slider = {
                puck = "#414868";
                backgroundhover = "#414868";
                background = "#565f89";
                primary = "#f7768e";
              };
              audio_slider = {
                puck = "#414868";
                backgroundhover = "#414868";
                background = "#565f89";
                primary = "#f7768e";
              };
              icons = {
                active = "#f7768e";
                passive = "#565f89";
              };
              iconbutton = {
                active = "#f7768e";
                passive = "#c0caf5";
              };
              listitems = {
                active = "#f7768e";
                passive = "#c0caf5";
              };
              border.color = "#414868";
              background.color = "#1a1b26";
            };
            media = {
              card.color = "#24283b";
              slider = {
                puck = "#565f89";
                backgroundhover = "#414868";
                background = "#565f89";
                primary = "#f7768e";
              };
              buttons = {
                text = "#1a1b26";
                background = "#bb9af7";
                enabled = "#73daca";
                inactive = "#414868";
              };
              border.color = "#414868";
              background.color = "#1a1b26";
              album = "#f7768e";
              artist = "#73daca";
              song = "#bb9af7";
            };
            power = {
              border.color = "#414868";
              buttons = {
                sleep = {
                  icon_background = "#7dcfff";
                  text = "#7dcfff";
                  background = "#24283b";
                  icon = "#1a1b26";
                };
                restart = {
                  text = "#e0af68";
                  icon_background = "#e0af68";
                  icon = "#1a1b26";
                  background = "#24283b";
                };
                shutdown = {
                  icon = "#1a1b26";
                  background = "#24283b";
                  icon_background = "#f7768e";
                  text = "#f7768e";
                };
                logout = {
                  icon = "#1a1b26";
                  background = "#24283b";
                  text = "#9ece6a";
                  icon_background = "#9ece6a";
                };
              };
              background.color = "#1a1b26";
              scaling = 90;
            };
          };
          background = "#1a1b26";
          text = "#c0caf5";
          border.color = "#414868";
          popover = {
            text = "#bb9af7";
            background = "#1a1b26";
            border = "#1a1b26";
          };
          tooltip = {
            text = "#c0caf5";
            background = "#1a1b26";
          };
          dropdownmenu = {
            divider = "#24283b";
            text = "#c0caf5";
            background = "#1a1b26";
          };
          slider = {
            puck = "#565f89";
            backgroundhover = "#414868";
            background = "#565f89";
            primary = "#bb9af7";
          };
          progressbar = {
            background = "#414868";
            foreground = "#bb9af7";
          };
          iconbuttons = {
            active = "#bb9af7";
            passive = "#c0caf5";
          };
          buttons = {
            text = "#1a1b26";
            disabled = "#565f89";
            active = "#f7768e";
            default = "#bb9af7";
          };
          switch = {
            puck = "#565f89";
            disabled = "#565f89";
            enabled = "#bb9af7";
          };
          icons = {
            active = "#bb9af7";
            passive = "#414868";
          };
          listitems = {
            active = "#bb9af7";
            passive = "#c0caf5";
          };
          label = "#bb9af7";
          feinttext = "#414868";
          dimtext = "#414868";
          cards = "#24283b";
          check_radio_button.background = "#3b4261";
          check_radio_button.active = "#bb9af7";
        };
        transparent = true;
        background = "#1a1b26";
        margin_sides = "0.0em";
        location = "top";
      };
      osd = {
        monitor = 1;
        muted_zero = true;
        label = "#bb9af7";
        icon = "#1a1b26";
        bar_overflow_color = "#f7768e";
        bar_empty_color = "#414868";
        bar_color = "#bb9af7";
        icon_container = "#bb9af7";
        bar_container = "#1a1b26";
      };
      notification = {
        close_button.label = "#1a1b26";
        close_button.background = "#f7768e";
        labelicon = "#bb9af7";
        text = "#c0caf5";
        time = "#9aa5ce";
        border = "#565f89";
        label = "#bb9af7";
        actions.text = "#24283b";
        actions.background = "#bb9af7";
        background = "#1a1b26";
      };
      font.size = "1.3rem";
    };
    notifications = {
      monitor = 1;
      active_monitor = false;
    };
    wallpaper = {
      pywal = false;
      image = "/home/cholli/Pictures/firewatch.jpg";
      enable = false;
    };
  };
in
{
  options.${namespace}.desktop.addons.hyprpanel = {
    enable = mkEnableOption "Enable HyprIdle";
    extraSettings = mkOption {
      default = { };
      inherit (settingsFormat) type;
      description = ''
        Additional Options to pass to hyprpanel
      '';
      example = literalExpression ''
        {
          
        }
      '';
    };
  };

  config = mkIf cfg.enable {

    snowfallorg.users.${username}.home.config = {
      wayland.windowManager.hyprland.settings.exec-once = [
        "${pkgs.hyprpanel}/bin/hyprpanel"
      ];
    };

    ${namespace}.home.file = {
      ".cache/ags/hyprpanel/options_test.json" = {

        # source = pkgs.formats.json.generate "options.json" settings;
        text = builtins.toJSON settings;
      };
    };
  };
}
