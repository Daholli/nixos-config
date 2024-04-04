{ channels, inputs, ... }:

final: prev: {
  vivaldi = prev.vivaldi.override { commandLineArgs = "--disable-features=AllowQt"; };
}
