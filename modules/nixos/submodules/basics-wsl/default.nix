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
      fastfetch

      fd
      tree
      ripgrep
      fzf
      eza

      wslu
      wsl-open

      zip
      unzip
    ];

    ${namespace} = {
      nix = {
        enable = true;

        extra-substituters = {
          "https://cache.lix.systems" = {
            key = "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=";
          };
          "https://nix-community.cachix.org" = {
            key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
          };
          "https://nixcache.christophhollizeck.dev" = {
            key = "christophhollizeck.dev:7pPAvm9xqFQB8FDApVNL6Tii1Jsv+Sj/LjEIkdeGhbA=";
          };
        };
      };

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
