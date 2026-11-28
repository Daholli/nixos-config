{
  description = "Infrastructure flake for my machines";

  outputs =
    { self, ... }@args:
    let
      pins = (import ./.tack) { overrides = args.tackOverrides or { }; };
      inputs = pins // {
        inherit self;
        nixpkgs-latest-factorio = pins.nixpkgs-master;
        nixpkgs-latest-minecraft = pins.nixpkgs-master;
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
