{
  flake.modules = {
    nixos.base =
      { pkgs, ... }:
      let

        reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
          ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
        '';
      in
      {
        services.pcscd.enable = true;
        services.udev.packages = with pkgs; [ yubikey-personalization ];

        environment.systemPackages = with pkgs; [
          cryptsetup
          paperkey
          gnupg
          pinentry-curses
          pinentry-qt

          yubikey-manager
          yubioath-flutter
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

      };

    homeManager.base =
      { inputs, pkgs, ... }:
      let
        gpgConf = "${inputs.gpg-base-conf}/gpg.conf";

        gpgAgentConf = ''
          enable-ssh-support
          default-cache-ttl 60
          max-cache-ttl 120
          pinentry-program ${pkgs.pinentry-qt}/bin/pinentry-qt
        '';
      in
      {
        home.file = {
          ".gnupg/.keep".text = "";

          ".gnupg/gpg.conf".source = gpgConf;
          ".gnupg/gpg-agent.conf".text = gpgAgentConf;
          ".gnupg/scdeamon.conf".text = "disable-ccid";
        };
      };
  };
}
