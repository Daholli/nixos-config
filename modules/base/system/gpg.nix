{
  flake.modules = {
    nixos.yubikey =
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
          gnupg
          cryptsetup
          paperkey
          pinentry-curses

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
            pinentryPackage = pkgs.pinentry-qt;
          };
        };
      };

    homeManager.base =
      {
        inputs,
        lib,
        osConfig,
        ...
      }:
      let
        gpgConf = "${inputs.gpg-base-conf}/gpg.conf";

        gpgAgentConf = ''
          enable-ssh-support
          default-cache-ttl 60
          max-cache-ttl 120
          pinentry-program ${lib.getExe osConfig.programs.gnupg.agent.pinentryPackage}
        '';
      in
      {
        home.file = lib.mkIf osConfig.programs.gnupg.agent.enable {
          ".gnupg/.keep".text = "";

          ".gnupg/gpg.conf".source = gpgConf;
          ".gnupg/gpg-agent.conf".text = gpgAgentConf;
          ".gnupg/scdeamon.conf".text = "disable-ccid";
        };
      };
  };
}
