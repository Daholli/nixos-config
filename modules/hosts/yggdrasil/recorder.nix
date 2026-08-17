topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      # imports = [
      #   inputs.modern-recorder.nixosModules.recorderSingleNode
      #   inputs.modern-recorder.nixosModules.recorderDevHost
      # ];

      # networking.firewall.trustedInterfaces = [
      #   "virbr0"
      #   "podman0"
      # ];

      # # rustfs-flake's own overlay carries the server only; the cli (rc) ships as
      # # a package of that flake, so pkgs.rustfs-cli -- which modern-recorder's
      # # rustfs module defaults to -- needs the extra overlay modern-recorder
      # # keeps alongside it.
      # nixpkgs.overlays = import "${inputs.modern-recorder}/nix/rustfs-overlays.nix" inputs.modern-recorder.inputs.rustfs;

      # services.recorderDevHost = {
      #   enable = true;
      #   user = topLevel.config.flake.meta.users.cholli.username;
      # };

      # services.recorderDevCameras = {
      #   enable = true;
      #   user = topLevel.config.flake.meta.users.cholli.username;
      #   mediaDir = "/home/${topLevel.config.flake.meta.users.cholli.username}/work/modern-recorder/test";
      # };

      # services.recorderSecretsFile = ../../../secrets/secrets-recorder.yaml;
      # services.recorderUserSecretsFile = ../../../secrets/secrets-recorder-users.yaml;
      # services.recorderMtlsSecretsFile = ../../../secrets/secrets-recorder-mtls.yaml;

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };
      users.users.cholli.extraGroups = [ "libvirtd" ];

      environment.etc."ssh-keys/cholli.pub".text =
        builtins.concatStringsSep "\n" topLevel.config.flake.meta.users.cholli.authorizedKeys;
    };
}
