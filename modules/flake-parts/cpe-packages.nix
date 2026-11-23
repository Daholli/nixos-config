# sbomnix reads CPEs from this flake's legacyPackages, keyed by pname.
{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      legacyPackages.hey = inputs.hey-cli.packages.${system}.hey;
    };
}
