{ channels, ... }:

final: prev: {
  tuya-vacuum = channels.nixpkgs-tuya-vacuum.python3Packages.tuya-vacuum;
}
