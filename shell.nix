{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.stack
    pkgs.haskell.compiler.ghc9103
    pkgs.nodejs_20
    pkgs.rsync
  ];

  NIXPKGS_ALLOW_INSECURE = "1";
}
