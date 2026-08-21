topLevel: {
  flake.modules.nixos."hosts/yggdrasil" =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      networking.firewall.trustedInterfaces = [
        "virbr0"
        "podman0"
      ];

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };

      programs.virt-manager.enable = true;
      users.users.cholli.extraGroups = [ "libvirtd" ];

      environment.etc."ssh-keys/cholli.pub".text =
        builtins.concatStringsSep "\n" topLevel.config.flake.meta.users.cholli.authorizedKeys;
    };
}
