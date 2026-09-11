# shell.nix
# nix-shell shell.nix

{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") { } }:
pkgs.mkShell {
  packages = with pkgs; [
    nixVersions.latest
    nixos-rebuild
  ];
}
