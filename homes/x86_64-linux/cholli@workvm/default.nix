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
    apps = {
      kitty = enabled;
    };

    tools = {
      direnv = enabled;
    };
  };
}
