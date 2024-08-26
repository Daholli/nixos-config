{
  description = "NixOs Config";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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
      inputs.nixpkgs.follows = "unstable";
    };

    ###
    # Snowfall dependencies
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "unstable";
    };

    kickstartnvim = {
      url = "github:Daholli/kickstart-nix-nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GPG default configuration
    gpg-base-conf = {
      url = "github:drduh/config";
      flake = false;
    };

    sops-nix.url = "github:Mic92/sops-nix";

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
        snowfall-flake.overlays.default
        kickstartnvim.overlays.default
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        nix-ld.nixosModules.nix-ld
        sops-nix.nixosModules.sops
      ];

      systems.hosts.wsl.modules = with inputs; [ nixos-wsl.nixosModules.default ];
    };
}
