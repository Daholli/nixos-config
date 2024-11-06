{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
with lib.${namespace};
let
  cfg = config.${namespace}.services.factorio-server;
  inherit (lib) mkIf mkOption mkEnableOption;
in
{
  options.${namespace}.services.factorio-server = {
    enable = mkEnableOption "Enable Factorio Headless Server";
    sopsFile = mkOption {
      type = lib.types.path;
      default = lib.snowfall.fs.get-file "secrets/secrets.yaml";
      description = "SecretFile";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.factorio-headless ];
    sops = {
      secrets = {
        factorio_token = {
          restartUnits = [ "factorio.service" ];
          inherit sopsFile;
        };
        factorio_username = {
          restartUnits = [ "factorio.service" ];
          inherit sopsFile;
        };
        factorio_game_password = {
          restartUnits = [ "factorio.service" ];
          inherit sopsFile;
        };
      };
      templates."extraSettingsFile.json".content = ''
        {
          "name": "SpaceAgeHolli",
          "description": "Trying to run a factorio-headless-server on my nix system",
          "tags": ["vanilla"],
          "max_players": 10,
          "game_password": "${config.sops.placeholder.factorio_game_password}",
          "allow_commands": "admins-only",
          "autosave_slots": 5,
          "ignore_player_limit_for_returning_players": true,
          "username" : "${config.sops.placeholder.factorio_username}",
          "token": "${config.sops.placeholder.factorio_token}"
        }
      '';
      templates."extraSettingsFile.json".mode = "0444";
    };

    services.factorio = {
      enable = true;
      openFirewall = true;
      public = true;
      lan = true;
      nonBlockingSaving = true;
      autosave-interval = 15;
      saveName = "SpaceAge";
      admins = [
        "daholli"
        "galbrain"
        "geigeabc"
      ];
      extraSettingsFile = config.sops.templates."extraSettingsFile.json".path;
    };
  };
}
