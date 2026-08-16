topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.modern-recorder.nixosModules.recorderSingleNode
        inputs.modern-recorder.nixosModules.recorderDevHost
      ];

      networking.firewall.trustedInterfaces = [
        "virbr0"
        "podman0"
      ];

      nixpkgs.overlays = [ inputs.modern-recorder.inputs.rustfs.overlays.default ];

      services.recorderDevHost = {
        enable = true;
        user = topLevel.config.flake.meta.users.cholli.username;
      };

      services.recorderDevCameras = {
        enable = true;
        user = topLevel.config.flake.meta.users.cholli.username;
        mediaDir = "/home/${topLevel.config.flake.meta.users.cholli.username}/work/modern-recorder/test";
      };

      services.recorderSecretsFile = ../../../secrets/secrets-recorder.yaml;
      services.recorderUserSecretsFile = ../../../secrets/secrets-recorder-users.yaml;
      services.recorderMtlsSecretsFile = ../../../secrets/secrets-recorder-mtls.yaml;

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
