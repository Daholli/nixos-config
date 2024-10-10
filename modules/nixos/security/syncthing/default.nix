{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.security.syncthing;
  user = config.${namespace}.user;
in
{
  options.${namespace}.security.syncthing = with types; {
    enable = mkEnableOption "Enable Syncthing";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = user.name;
      dataDir = "/home/" + user.name + "/Documents";
      configDir = "/home/" + user.name + "/Documents/.config/syncthing";
      settings = {
        folders = {
          "Documents" = {
            # Name of folder in Syncthing, also the folder ID
            path = "/home/" + user.name + "/Documents"; # Which folder to add to Syncthing
          };
          "Pictures" = {
            path = "/home/" + user.name + "/Pictures";
          };
          "7vfj7-k83xj" = {
            path = "/home/" + user.name + "/WhatsApp Documents";
          };
        };
        gui = {
          theme = "black";
        };
      };
    };

    # Syncthing ports: 8384 for remote access to GUI
    # 22000 TCP and/or UDP for sync traffic
    # 21027/UDP for discovery
    # source: https://docs.syncthing.net/users/firewall.html
    networking.firewall.allowedTCPPorts = [
      8384
      22000
    ];
    networking.firewall.allowedUDPPorts = [
      22000
      21027
    ];
  };
}
