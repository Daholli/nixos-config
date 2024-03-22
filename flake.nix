{
  description = "My NixOS / nix-darwin / nixos-generators systems";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      channels-config = {allowUnfree = true;};

      outputs-builder = channels: {formatter = channels.nixpkgs.alejandra;};

      overlays = with inputs; [
        # Use the overlay provided by this flake.
        snowfall-flake.overlays."package/flake"
      ];
    };
}
