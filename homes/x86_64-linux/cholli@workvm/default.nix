{
  lib,
  pkgs,
  config,
  osConfig ? {},
  format ? "unknown",
  ...
}:
with lib.wyrdgard; {
  wyrdgard = {
    apps.cli-apps = {
      kitty = enabled;
      home-manager = enabled;
    };

    tools = {
      direnv = enabled;
    };
  };
}
