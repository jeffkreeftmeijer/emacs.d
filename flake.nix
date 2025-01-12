{
  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = {
    nixpkgs,
    flake-utils,
    emacs-overlay,
    ...
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ emacs-overlay.overlay ];
    };
    configured-emacs = pkgs.callPackage ./configured-emacs.nix {};
  in {
    packages.configured-emacs = configured-emacs;
    packages.default = configured-emacs;

    devShell = pkgs.mkShell {
      buildInputs = [pkgs.pre-commit];
      shellHook = "pre-commit install > /dev/null";
    };
  });
}
