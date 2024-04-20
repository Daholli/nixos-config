{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.apps.factorio-server;
  inherit (config.wyrdgard.user) name;
in
{
  options.wyrdgard.apps.factorio-server = with types; {
    enable = mkEnableOption "Enable Factorio Headless Server";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ factorio-headless-experimental ];

    services.factorio = {
      enable = true;
      openFirewall = true;
      public = true;
      lan = true;
      bind = "[::]";
      nonBlockingSaving = true;
      autosave-interval = 5;
      loadLatestSave = true;
      username = "DaHolli";
      token = "4d4624ca9a23396e1955c1b4b364ff";
      game-name = "Alles Nix!";
      game-password = "1234";
    };
  };
}
