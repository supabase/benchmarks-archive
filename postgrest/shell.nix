let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-20.03";
    url = "https://github.com/nixos/nixpkgs/archive/7bc3a08d3a4c700b53a3b27f5acd149f24b931ec.tar.gz";
    sha256 = "1kiz37052zsgvw7a378zg08mpbi1wk8dkgm5j6dy0x4mxvcg8ws3";
  };
  pkgs = import nixpkgs {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.nixops
  ];
  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
  ''; # Needed by nixops to use the pinned version
}
