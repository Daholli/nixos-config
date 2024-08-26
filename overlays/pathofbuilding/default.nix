{ channels, ... }:

final: prev: { inherit (channels.unstable) pobfrontend; }
