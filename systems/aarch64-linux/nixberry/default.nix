{
  lib,
  modulesPath,
  inputs,
  namespace,
  ...
}:

with lib.${namespace};
let
  inherit (lib) mkForce;
in
{
  imports = with inputs.nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    raspberry-pi-5
  ];

  ${namespace} = {

    submodules = {
      basics = enabled;
    };

    system = {
      boot = {
        # Raspberry Pi requires a specific bootloader.
        enable = mkForce false;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
