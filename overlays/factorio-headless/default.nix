{ channels, ... }:

final: prev: { inherit (channels.nixpkgs-latest-factorio) factorio-headless; }
