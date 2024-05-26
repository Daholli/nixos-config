{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.nix;
in
{
  options.wyrdgard.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.nixVersions.git "Which nix package to use.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      snowfallorg.flake
      nixfmt-rfc-style
      nix-prefetch-git
      nix-du
    ];

    nix =
      let
        users = [
          "root"
          config.wyrdgard.user.name
        ];
      in
      {
        package = cfg.package;

        settings =
          {
            experimental-features = "nix-command flakes";
            http-connections = 50;
            warn-dirty = false;
            log-lines = 50;
            sandbox = "relaxed";
            auto-optimise-store = true;
            trusted-users = users;
            allowed-users = users;
          }
          // (lib.optionalAttrs config.wyrdgard.tools.direnv.enable {
            keep-outputs = true;
            keep-derivations = true;
          });

        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };

        # flake-utils-plus
        generateRegistryFromInputs = true;
        generateNixPathFromInputs = true;
        linkInputs = true;
      };
  };
}
