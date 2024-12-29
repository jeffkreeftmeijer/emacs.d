{ pkgs ? import <nixpkgs> {
  overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/97678931872b1bad445ed341e083c09025b4f0e7.tar.gz;
    }))
  ];
} }:

pkgs.emacsWithPackagesFromUsePackage {
  config = ./default.el;
  defaultInitFile = true;
}
