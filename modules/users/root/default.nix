{
  config,
  ...
}:
{
  flake = {
    modules.nixos.root =
      { pkgs, ... }:
      {
        programs.fish.enable = true;

        users.users.root = {
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = config.flake.meta.users.cholli.authorizedKeys;
          initialPassword = "asdf1234";
        };
      };
  };
}
