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
        "factorio/token" = {
          restartUnits = [ "factorio.service" ];
          inherit (cfg) sopsFile;
        };
        "factorio/username" = {
          restartUnits = [ "factorio.service" ];
          inherit (cfg) sopsFile;
        };
        "factorio/game_password" = {
          restartUnits = [ "factorio.service" ];
          inherit (cfg) sopsFile;
        };
      };
      templates."extraSettingsFile.json".content = ''
        {
          "name": "Pyanodons Holli",
          "description": "Trying to run a factorio-headless-server on my nix system",
          "tags": ["vanilla"],
          "max_players": 10,
          "game_password": "${config.sops.placeholder."factorio/game_password"}",
          "allow_commands": "admins-only",
          "autosave_slots": 5,
          "ignore_player_limit_for_returning_players": true,
          "username" : "${config.sops.placeholder."factorio/username"}",
          "token": "${config.sops.placeholder."factorio/token"}"
        }
      '';
      templates."extraSettingsFile.json".mode = "0444";
    };

    systemd.tmpfiles.rules = [
      "Z /var/lib/factorio/mods 770 65400 65400 - -"
      "Z /var/lib/factorio/saves 770 65400 65400 - -"
    ];

    services.factorio = {
      enable = true;
      openFirewall = true;
      public = true;
      lan = true;
      nonBlockingSaving = true;
      autosave-interval = 5;
      saveName = "Pyanodons";
      loadLatestSave = true;
      admins = [
        "daholli"
        "galbrain"
        "geigeabc"
      ];
      extraSettingsFile = config.sops.templates."extraSettingsFile.json".path;
    };
  };
}
