{
  flake.modules.nixos.server =
    { ... }:
    {
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
