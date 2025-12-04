{
  flake.modules.nixos."hosts/nixberry" =
    { config, ... }:
    {

      sops.secrets = {
        "samba/cholli" = {
          sopsFile = ../../../secrets/secrets.yaml;
        };
      };

      services = {
        samba = {
          enable = true;
          openFirewall = true;

          settings = {
            global = {
              "smb3 unix extensions" = "yes";
            };

            cholli = {
              path = "/storage/cholli";
              browsable = "yes";
              writable = "yes";
              "create mask" = "0664";
              "directory mask" = "0775";
              "force group" = "users";
            };

            kaman = {
              path = "/storage/kaman";
              browsable = "yes";
              writable = "yes";
              "create mask" = "0664";
              "directory mask" = "0775";
              "force group" = "users";
            };

          };

        };

        avahi.enable = true;
        samba-wsdd = {
          enable = true;
          openFirewall = true;
        };
      };

      # add user passwords
      systemd.services.samba-smbd.postStart =
        let
          users = [
            "cholli"
          ];
          setupUser =
            user:
            let
              passwordPath = config.sops.secrets."samba/${user}".path;
              smbpasswd = "${config.services.samba.package}/bin/smbpasswd";
            in
            ''
              (echo $(< ${passwordPath});
               echo $(< ${passwordPath})) | \
                ${smbpasswd} -s -a ${user}
            '';
        in
        ''
          ${builtins.concatStringsSep "\n" (map setupUser users)}
        '';
    };
}
