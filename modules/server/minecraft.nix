{
  flake.modules.nixos.minecraft-server =
    { ... }:
    {
      services.minecraft-server = {
        enable = true;
        eula = true;
        openFirewall = true; # Opens the port the server is running on (by default 25565 but in this case 43000)
        declarative = true;
        whitelist = {
          # This is a mapping from Minecraft usernames to UUIDs. You can use https://mcuuid.net/ to get a Minecraft UUID for a username
          Daholli = "9e206940-3dfc-4331-b781-b43a9905087a";
        };
        serverProperties = {
          server-port = 43000;
          difficulty = 3;
          gamemode = 1;
          max-players = 5;
          motd = "NixOS Minecraft server!";
          white-list = true;
        };
        jvmOpts = "-Xms2048M -Xmx4096M";
      };
    };
}
