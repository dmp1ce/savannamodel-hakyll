{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.stack
    pkgs.nodejs_20
    pkgs.rsync
  ];
}
