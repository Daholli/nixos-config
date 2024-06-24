{
  options,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with lib.wyrdgard;
let
  cfg = config.wyrdgard.security.gpg;

  gpgConf = "${inputs.gpg-base-conf}/gpg.conf";

  gpgAgentConf = ''
    enable-ssh-support
    default-cache-ttl 60
    max-cache-ttl 120
    pinentry-program ${pkgs.pinentry-qt}/bin/pinentry-qt
  '';

  reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
    ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
  '';
in
{
  options.wyrdgard.security.gpg = with types; {
    enable = mkBoolOpt false "Wether or not to enable GPG.";
    agentTimeout = mkOpt int 5 "The amount of time to wait before continuing with shell init.";
  };

  config = mkIf cfg.enable {
    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [ yubikey-personalization ];

    environment.systemPackages = with pkgs; [
      cryptsetup
      paperkey
      gnupg
      pinentry-curses
      pinentry-qt

      yubikey-manager
      yubikey-manager-qt
      reload-yubikey
    ];

    programs = {
      ssh.startAgent = false;

      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        enableExtraSocket = true;
      };
    };

    wyrdgard = {
      home.file = {
        ".gnupg/.keep".text = "";

        ".gnupg/gpg.conf".source = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
        ".gnupg/scdeamon.conf".text = "disable-ccid";
        # YUBIKEYCERTIFYPASSWORD
      };
    };
  };
}
