{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.submodules.basics-wsl;
in
{
  options.${namespace}.submodules.basics-wsl = {
    enable = mkBoolOpt false "Whether or not to enable basic configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      neofetch

      fd
      tree
      ripgrep
      fzf
      eza

      wslu
      wsl-open
    ];

    ${namespace} = {
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
