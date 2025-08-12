{pkgs ? import <nixpkgs> {}}:
with pkgs;
  mkShell {
    buildInputs = [
      nixd
      nixfmt-rfc-style
      alejandra
    ];
  }
