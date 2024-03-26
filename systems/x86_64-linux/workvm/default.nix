{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.wyrdgard; {
  imports = [./hardware.nix];

  boot.blacklistedKernelModules = ["hyperv-fb"];
  virtualisation.hypervGuest.videoMode = "1920x1080";

  environment.systemPackages = with pkgs; [

  ];

  environment.variables.EDITOR = "nvim";
  environment.variables.SUDOEDITOR = "nvim";

  # Configure Home-Manager options from NixOS.
  snowfallorg.user.cholli.home.config = {
    programs.kitty = {
      theme = "Tokyo Night";
      shellIntegration.enableFishIntegration = true;
    };
  };

  wyrdgard = {
    apps = {
      vivaldi = enabled;
    };

    submodules = {
      basics = enabled;
      graphical-interface = enabled;
      socials = enabled;
    };
  };

  system.stateVersion = "23.11";
}
