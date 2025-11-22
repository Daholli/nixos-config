{
  config,
  ...
}:
{
  flake = {
    meta.users = {
      cholli = {
        email = "christoph.hollizeck@hey.com";
        name = "Christoph Hollizeck";
        username = "cholli";

        key = "ACCFA2DB47795D9E";

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFrDiO5+vMfD5MimkzN32iw3MnSMLZ0mHvOrHVVmLD0"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4Pr7p0jizrvIl0UhcvrmL5SHRQQQWIcHLAnRFyUZS6"
        ];

      };
    };

    modules = {
      nixos.cholli =
        { pkgs, ... }:
        {
          programs.fish.enable = true;

          users.users.cholli = {
            description = config.flake.meta.users.cholli.name;
            isNormalUser = true;
            createHome = true;
            extraGroups = [
              "audio"
              "input"
              "networkmanager"
              "sound"
              "tty"
              "wheel"
            ];
            shell = pkgs.fish;
            # TODO: fix this with sops
            initialPassword = "asdf";

            openssh.authorizedKeys.keys = config.flake.meta.users.cholli.authorizedKeys;
          };

          nix.settings.trusted-users = [ config.flake.meta.users.cholli.username ];

        };

      homeManager.cholli =
        {
          lib,
          osConfig,
          pkgs,
          ...
        }:
        let
          defaultIconFileName = "profile.png";
        in
        {
          home = {
            file = {
              "Desktop/.keep".text = "";
              "Documents/.keep".text = "";
              "Downloads/.keep".text = "";
              "Music/.keep".text = "";
              "Pictures/.keep".text = "";
              "Videos/.keep".text = "";
              ".face".source = ./${defaultIconFileName};
              "Pictures/${defaultIconFileName}".source = ./${defaultIconFileName};
            }
            // lib.optionalAttrs (osConfig.networking.hostName == "yggdrasil") {
              # Some Paths for my main machine
              "projects/NixOS/.keep".text = "";
              "projects/nix-community/.keep".text = "";
              "projects/niri/.keep".text = "";
              "work/.keep".text = "";
            };

            packages = with pkgs; [ graphviz ];
            shellAliases = {
              nixsize = "nix-du -n=50 | dot -Tsvg > ~/Pictures/store.svg";
            };

          };
        };
    };
  };
}
