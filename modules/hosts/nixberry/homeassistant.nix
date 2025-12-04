{
  flake.modules.nixos."hosts/nixberry" =
    { pkgs, ... }:
    {
      services.home-assistant = {
        enable = false;
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
        ];

        customComponents = with pkgs.home-assistant-custom-components; [
          smartthinq-sensors
          sleep_as_android
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

          lovelace = {
            # mode = "yaml";
            resources = [
              {
                url = "/local/nixos-lovelace-modules/vacuum-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/bubble-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/clock-weather-card.js";
                type = "module";
              }
              {
                url = "/local/nixos-lovelace-modules/mushroom.js";
                type = "module";
              }
            ];
          };

          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [
              "100.86.250.97" # loptland tailscale
            ];
          };
        };
        openFirewall = true;
      };
    };
}
