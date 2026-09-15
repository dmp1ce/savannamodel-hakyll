{ pkgs ? import <nixpkgs> {} }:

# Node/npm are intentionally NOT included: nodejs is not in the binary
# cache for the current channel (builds from source, ~30 min). For local
# site builds copy the compiled CSS from the deployed repo instead:
#   rsync -a ../savannamodel-website/docs/semantic/dist/ semantic/dist/
pkgs.mkShell {
  buildInputs = [
    pkgs.stack
    pkgs.haskell.compiler.ghc9103
    pkgs.rsync
    pkgs.pkg-config
    pkgs.zlib
  ];
}
