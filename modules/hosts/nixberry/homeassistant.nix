{
  flake.modules.nixos."hosts/nixberry" =
    { pkgs, ... }:
    {
      services.home-assistant = {
        enable = true;
        configWritable = true;
        extraComponents = [
          "default_config"
          "analytics"
          "shopping_list"
          "fritzbox"
          "met"
          "esphome"
          "rpi_power"
          "tuya"
          "sonos"
        ];

        customComponents = with pkgs.home-assistant-custom-components; [
          smartthinq-sensors
        ];

        extraPackages =
          python3Packages: with python3Packages; [
            ical
          ];

        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          mushroom
          bubble-card
          clock-weather-card
          vacuum-card
        ];

        config = {
          homeassistant = {
            latitude = 49.4;
            longitude = 8.6;
            temperature_unit = "C";
            unit_system = "metric";

            external_url = "https://ha.christophhollizeck.dev";
            internal_url = "http://192.168.178.2:8123";
          };

          default_config = "";

          mobile_app = "";
          recorder = "";

          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [
              "100.86.250.97" # loptland tailscale
            ];
          };
        };

        lovelaceConfigWritable = true;
        lovelaceConfig = [
          {
            tile = "main-dashboard";
            views = [
              {
                title = "Home";
                sections = [
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "map";
                        entities = [
                          { entity = "person.christoph_hollizeck"; }
                          { entity = "person.kuralay_aman"; }
                          { entity = "zone.home"; }
                        ];
                        theme_mode = "auto";
                        grid_options = {
                          columns = "full";
                          rows = 6;
                        };
                      }
                      {
                        show_current = true;
                        show_forecast = true;
                        type = "weather-forecast";
                        entity = "weather.forecast_home";
                        forecast_type = "hourly";
                        forecast_slots = 5;
                      }
                      {
                        display_order = "duedate_asc";
                        type = "todo-list";
                        entity = "todo.shopping_list";
                        title = "Shopping List";
                        hide_completed = true;
                      }
                    ];
                  }
                ];
                badges = [
                  {
                    type = "entity";
                    show_name = true;
                    show_state = true;
                    show_icon = true;
                    entity = "person.christoph_hollizeck";
                    name = {
                      type = "entity";
                    };
                    show_entity_picture = true;
                  }
                  {
                    type = "entity";
                    show_name = true;
                    show_state = true;
                    show_icon = true;
                    entity = "person.kuralay_aman";
                    show_entity_picture = true;
                  }
                ];
                header = {
                  layout = "center";
                  badges_position = "bottom";
                  badges_wrap = "scroll";
                  card = {
                    type = "markdown";
                    text_only = true;
                    content = "# Hello {{ user }}\n";
                  };
                };
              }
              {
                type = "sections";
                max_columns = 2;
                title = "living-room";
                path = "living-room";
                sections = [
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "history-graph";
                        entities = [ { entity = "sensor.living_room_temperature"; } ];
                        title = "Temperature";
                      }
                    ];
                  }
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "history-graph";
                        entities = [ { entity = "sensor.living_room_humidity"; } ];
                        title = "Humidity";
                      }
                    ];
                  }
                ];
                cards = [ ];
              }
              {
                type = "sections";
                max_columns = 3;
                title = "kitchen";
                path = "kitchen";
                sections = [
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "thermostat";
                        entity = "climate.kueche_radiator";
                      }
                    ];
                  }
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "custom:vacuum-card";
                        entity = "vacuum.sl60d";
                      }
                    ];
                  }
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "glance";
                        entities = [
                          {
                            entity = "switch.kettle_socket_1";
                            name = {
                              type = "device";
                            };
                            show_last_changed = true;
                          }
                          { entity = "sensor.kettle_total_energy"; }
                        ];
                      }
                      {
                        show_name = true;
                        show_icon = true;
                        show_state = true;
                        type = "glance";
                        entities = [
                          {
                            entity = "switch.shelf_socket_1";
                            show_last_changed = true;
                            name = {
                              type = "device";
                            };
                          }
                          { entity = "sensor.shelf_total_energy"; }
                        ];
                        state_color = true;
                      }
                    ];
                  }
                ];
              }
              {
                type = "sections";
                max_columns = 3;
                title = "bedroom";
                path = "bedroom";
                sections = [
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "thermostat";
                        entity = "climate.bedroom_radiator";
                      }
                    ];
                  }
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "history-graph";
                        entities = [ { entity = "sensor.bedroom_temperature"; } ];
                        title = "Temperature";
                      }
                    ];
                  }
                  {
                    type = "grid";
                    cards = [
                      {
                        type = "history-graph";
                        entities = [ { entity = "sensor.bedroom_humidity"; } ];
                        title = "Humidity";
                      }
                    ];
                  }
                ];
              }
            ];

          }
        ];
        openFirewall = true;
      };
    };
}
