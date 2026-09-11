{
  flake.modules =
    let
      stateVersion = "25.05";
    in
    {
      homeManager.base =
        { inputs, ... }:
        {
          imports = [
            inputs.sops-nix.homeManagerModules.sops
          ];

          home = {
            inherit stateVersion;
          };

          catppuccin = {
            enable = true;
            autoEnable = true;
            flavor = "mocha";
            accent = "lavender";
          };
        };

      nixos.base =
        {
          inputs,
          pkgs,
          ...
        }:
        {
          imports = [
            inputs.sops-nix.nixosModules.sops
            inputs.niri-flake.nixosModules.niri
            inputs.catppuccin.nixosModules.catppuccin
          ];

          catppuccin = {
            enable = true;
            autoEnable = true;
            flavor = "mocha";
            accent = "lavender";
          };

          environment.systemPackages = with pkgs; [
            sops
            age
            ssh-to-age
          ];

          services.gnome.gnome-keyring.enable = true;

          services.dbus.packages = [
            pkgs.gnome-keyring
            pkgs.gcr_3
          ];

          sops = {
            defaultSopsFormat = "yaml";

            age = {
              sshKeyPaths = [
                "/etc/ssh/ssh_host_ed25519_key"
              ];
            };

          };

          system = {
            # This value determines the NixOS release from which the default
            # settings for stateful data, like file locations and database versions
            # on your system were taken. It‘s perfectly fine and recommended to leave
            # this value at the release version of the first install of this system.
            # Before changing this value read the documentation for this option
            # (e.g. man configuration.nix or on https://search.nixos.org/options?&show=system.stateVersion&from=0&size=50&sort=relevance&type=packages&query=stateVersion).
            inherit stateVersion;
          };
        };
    };
}
