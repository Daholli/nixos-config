{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.security.sops;
in
{
  options.${namespace}.security.sops = with types; {
    enable = mkBoolOpt true "Enable sops (Default true)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    sops = {
      defaultSopsFile = lib.snowfall.fs.get-file "secrets/secrets.yaml";
      defaultSopsFormat = "yaml";

      # age.keyFile = "/home/cholli/.config/sops/age/keys.txt";
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
