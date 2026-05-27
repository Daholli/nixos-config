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

  };
}
