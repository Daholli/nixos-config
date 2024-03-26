{ pkgs, config, lib, ... }:
with lib;
with lib.wyrdgard;
{
  imports = [ ./hardware.nix ];

  boot.blacklistedKernelModules = [ "hyperv-fb" ];
  virtualisation.hypervGuest.videoMode = "1920x1080";

  environment.systemPackages = with pkgs; [
    kitty
    fish
    fishPlugins.tide

    fd
    tree
    ripgrep
  ];

  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma5.enable = true;
    layout = "us";
    xkbVariant = "";
  };

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
      discord = enabled;
      vivaldi = enabled;
    };

    submodules = {
      basics = enabled;
    };
  };

  system.stateVersion = "23.11";
}
