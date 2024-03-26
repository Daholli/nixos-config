{ pkgs, config, lib, ... }:
with lib;
with lib.wyrdgard;
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    fd
    tree
    ripgrep
  ];

  # nvidia
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  environment.pathsToLink = [ "/libexec" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  wyrdgard = {
    archetypes = {
      gaming.enable = true;
    };

    apps = {
      cli-apps = {
        fish = enabled;
      };
      vivaldi = enabled;
      discord = enabled;
      _1password = enabled;
    };
  };

  # Configure Home-Manager options from NixOS.
  snowfallorg.user.cholli.home.config = {
    programs.kitty = {
      theme = "Tokyo Night";
      shellIntegration.enableFishIntegration = true;
    };
  };

  system.stateVersion = "23.11";
}
