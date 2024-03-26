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
      fish = enabled;
      home-manager = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };
}
