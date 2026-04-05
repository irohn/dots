{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs.buildPackages; [
    nixd
    alejandra
    lua-language-server
    stylua
  ];
}
