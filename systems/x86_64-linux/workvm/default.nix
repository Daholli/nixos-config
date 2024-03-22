{
  pkgs,
  config,
  ...
}: {
  imports = [./hardware.nix];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = ["hyperv-fb"];
  virtualisation.hypervGuest.videoMode = "1920x1080";

  users.users.cholli = {
    isNormalUser = true;
    extraGroups = ["wheel"];
  };

  environment.systemPackages = with pkgs; [
    neovim
    snowfallorg.flake
    git
    gitAndTools.gh
    kitty
    fish
    vim
    vivaldi

    fd
    tree
    ripgrep

    nixfmt
  ];

  home-manager.useGlobalPkgs = true;

  networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
    layout = "us";
    xkbVariant = "";
  };

  # Configure Home-Manager options from NixOS.
  snowfallorg.user.cholli.home.config = {};

  system.stateVersion = "23.11";
}
