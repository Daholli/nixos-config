{
  pkgs,
  mkShell,
  ...
}:
mkShell {
  # Create your shell
  nativeBuildInputs = with pkgs; [
    jdt-language-server
    zulu8
    zulu21
  ];
}