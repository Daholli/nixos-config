{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.nix;

  substituters-submodule = types.submodule (
    { name, ... }:
    {
      options = with types; {
        key = mkOpt (nullOr str) null "The trusted public key for this substituter.";
      };
    }
  );
in
{
  options.${namespace}.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt package pkgs.lix "Which nix package to use.";

    default-substituter = {
      url = mkOpt str "https://cache.nixos.org" "The url for the substituter.";
      key =
        mkOpt str "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "The trusted public key for the substituter.";
    };

    extra-substituters = mkOpt (attrsOf substituters-submodule) { } "Extra substituters to configure.";
  };

  config = mkIf cfg.enable {
    assertions = mapAttrsToList (name: value: {
      assertion = value.key != null;
      message = "plusultra.nix.extra-substituters.${name}.key must be set";
    }) cfg.extra-substituters;

    environment.systemPackages = with pkgs; [
      nixfmt-rfc-style
      nix-prefetch-git
      nix-du

      nix-weather
      nix-index
      nix-output-monitor
    ];

    programs.nh = {
      enable = true;
      package = inputs.nh-flake.packages.${system}.nh;
      flake = "/home/cholli/projects/config";
    };

    nix =
      let
        users = [
          "root"
          config.${namespace}.user.name
          "gitea-runner"
        ] ++ optional config.services.hydra.enable "hydra hydra-www hydra-evaluator hydra-queue-runner";
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
            allowed-uris = "github: https://github.com/ git+https://github.com/ gitlab: https://gitlab.com/ git+https://gitlab.com/";
            substituters = [
              cfg.default-substituter.url
            ] ++ (mapAttrsToList (name: value: name) cfg.extra-substituters);
            trusted-public-keys = [
              cfg.default-substituter.key
            ] ++ (mapAttrsToList (name: value: value.key) cfg.extra-substituters);
          }
          // (lib.optionalAttrs config.${namespace}.tools.direnv.enable {
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
