{
  lib,
  pkgs,
  config,
  namespace,
  osConfig ? { },
  format ? "unknown",
  ...
}:
with lib.${namespace};
{
  wyrdgard = {
    apps = {
      kitty = enabled;
    };

    tools = {
      direnv = enabled;
    };
  };
}
