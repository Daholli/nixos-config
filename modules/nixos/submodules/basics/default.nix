{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.submodules.basics;
in
{
  options.wyrdgard.submodules.basics = with types; {
    enable = mkBoolOpt false "Whether or not to enable basic configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [

    ];

    wyrdgard = {
      nix = enabled;

      tools = {
        git = enabled;
        nix-ld = enabled;
      };

      hardware = {
        audio = enabled;
        bluetooth = enabled;
        networking = enabled;
      };

      system = {
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        time = enabled;
        xkb = enabled;
      };
    };
  };
}
