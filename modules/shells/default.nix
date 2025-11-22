{
  inputs,
  ...
}:
let
  supportedSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  forAllSystems = f: inputs.nixpkgs.lib.genAttrs supportedSystems (system: f system);
in
{
  flake.devShells = forAllSystems (
    system:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    {
      default = pkgs.mkShell {
        packages = with pkgs; [ atool ];
      };

      zig = pkgs.mkShell {
        packages = [
          inputs.zig-overlay.packages.${system}.master
          inputs.zls.packages.${system}.zls
        ];
      };
    }
  );
}
