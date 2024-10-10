{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.wyrdgard) mkBoolOpt enabled;
  cfg = config.wyrdgard.submodules.basics-wsl;
in
{
  options.wyrdgard.submodules.basics-wsl = {
    enable = mkBoolOpt false "Whether or not to enable basic configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch

      fd
      tree
      ripgrep
      fzf
      colorls

      wslu
      wsl-open
    ];

    wyrdgard = {
      nix = enabled;

      apps.cli-apps.helix = enabled;

      tools = {
        git = enabled;
      };

      system.hardware = {
        networking = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
        xkb = enabled;
      };
    };
  };
}
