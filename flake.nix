{
  description = "NixOs Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-latest-factorio.url = "github:Daholli/nixpkgs/1f36f691a2a05eb0785d35164ba03962607348bf";
    nixpkgs-tuya-vacuum.url = "github:Daholli/nixpkgs/84b34e39e7a0879367189f34401191f6a0364bcf";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Run unpatched dynamically compiled binaries
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ###
    # hyprland stuff
    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock.url = "github:hyprwm/hyprlock";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";

    ###
    # Snowfall dependencies
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GPG default configuration
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    sops-nix.url = "github:Mic92/sops-nix";

    ## temporary
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    raspberry-pi-nix = {
      url = "github:JamieMagee/raspberry-pi-nix/25118248489e047a7da43a21409b457aa2af315e";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/b4fbffe79c00f19be94b86b4144ff67541613659";
    catppuccin.url = "github:catppuccin/nix";

    ###############
    # homeassitant

    tuya-vaccum-maps = {
      url = "github:jaidenlabelle/tuya-vacuum-maps";
      flake = false;
    };

    ################
    ## inputs for dev shells

    # rust
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "wyrdgard";
            title = "Wyrdgard";
          };

          namespace = "wyrdgard";
        };
      };
    in
    lib.mkFlake {
      channels-config = {
        allowUnfree = true;
      };

      outputs-builder = channels: { formatter = channels.nixpkgs.nixfmt-rfc-style; };

      overlays = with inputs; [
        hyprpanel.overlay
      ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        nix-ld.nixosModules.nix-ld
        sops-nix.nixosModules.sops

        catppuccin.nixosModules.catppuccin
      ];

      systems.hosts.nixberry.modules = with inputs; [
        raspberry-pi-nix.nixosModules.raspberry-pi
        raspberry-pi-nix.nixosModules.sd-image
      ];

      systems.hosts.loptland.modules = with inputs; [
        simple-nixos-mailserver.nixosModules.default
      ];

      systems.hosts.wsl.modules = with inputs; [ nixos-wsl.nixosModules.default ];
    }
    // rec {
      self = inputs.self;

      hydraJobs = {
        hosts = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.outputs.nixosConfigurations;
        packages = self.packages;
      };
    };
}
