{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,

  # The namespace used for your flake, defaulting to "internal" if not set.
  namespace,

  # All other arguments come from NixPkgs. You can use `pkgs` to pull shells or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  mkShell,
  system,
  ...
}:
let
  fenix =
    with inputs.fenix.packages.${system};
    combine [
      latest.toolchain
      targets.wasm32-unknown-unknown.latest.rust-std
    ];
in
mkShell {
  # Create your shell
  nativeBuildInputs = [
    fenix
    pkgs.llvmPackages.bintools
    pkgs.wasm-pack
  ];

  CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "lld";
}
