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
          };

          nix.settings.trusted-users = [ config.flake.meta.users.cholli.username ];

        };

      homeManager.cholli =
        { ... }:
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
              "projects/.keep".text = "";
              ".face".source = ./${defaultIconFileName};
              "Pictures/${defaultIconFileName}".source = ./${defaultIconFileName};
            };
          };
        };
    };
  };
}
