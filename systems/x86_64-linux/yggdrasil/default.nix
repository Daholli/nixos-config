{pkgs
, config
, ...
}: {
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.cholli = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    snowfallorg.flake
    git
    gitAndTools.gh
    kitty
    fish
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
  snowfallorg.user.cholli.home.config = { };

  system.stateVersion = "23.11";
}
