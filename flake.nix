{
  description = "Infrastructure flake for my machines";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    catppuccin.url = "github:catppuccin/nix";
    sops-nix.url = "github:Mic92/sops-nix";

    nixpkgs-latest-factorio.url = "github:Daholli/nixpkgs/e880129391be2f558d6c205cfd931be338b3b707";
    nixpkgs-latest-minecraft.url = "github:ChandlerSwift/nixpkgs/487be302ead911dc24db3068f6d9631f2db7585d";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh-flake = {
      url = "github:nix-community/nh/f1d08030e1ca3829fa26f9bc720119b62f5b09f0";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Support for special cases
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-raspberrypi = {
      url = "github:Daholli/nixos-raspberrypi/develop";
      inputs.nixpkgs.follows = "nixpkgs-rpi";
    };
    nixpkgs-rpi.url = "github:nvmd/nixpkgs/modules-with-keys-25.11";

    nixos-images = {
      url = "github:nvmd/nixos-images/sdimage-installer";
      inputs.nixos-stable.follows = "nixpkgs-rpi";
      inputs.nixos-unstable.follows = "nixpkgs-rpi";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ###
    # hyprland stuff
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    ###
    # Niri
    niri = {
      url = "github:YaLTeR/niri";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "";
      };
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell/v1.0.2";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      # url = "github:Daholli/niri-flake/1067d35dd18f6a55f79873c944f1427a9eb7caa7"; # for debugging
      inputs = {
        niri-stable.follows = "niri";
        nixpkgs.follows = "nixpkgs";
      };
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gpg-base-conf = {
      url = "github:drduh/config"; # GPG default configuration
      flake = false;
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

    ###
    # inputs for dev shells
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zig
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-overlay";
    };
  };
}
