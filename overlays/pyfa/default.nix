{ channels, ... }:

final: prev: { inherit (channels.nixpkgs-pyfa) pyfa; }
