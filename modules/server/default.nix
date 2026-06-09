{
  flake.modules.nixos.server = _: {
    programs.tmux = {
      enable = true;

      clock24 = true;
      newSession = true;
      keyMode = "vi";
      terminal = "kitty";
      extraConfig = ''
        set -g mouse on
      '';
    };

    system.autoUpgrade = {
      enable = true;
      flake = "git+https://git.christophhollizeck.dev/Daholli/nixos-config";
      dates = "weekly";
      randomizedDelaySec = "6h";
      allowReboot = false;
    };

  };
}
