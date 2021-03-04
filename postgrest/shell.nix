let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-20.03";
    url = "https://github.com/nixos/nixpkgs/archive/7bc3a08d3a4c700b53a3b27f5acd149f24b931ec.tar.gz";
    sha256 = "1kiz37052zsgvw7a378zg08mpbi1wk8dkgm5j6dy0x4mxvcg8ws3";
  };
  pkgs = import nixpkgs {};
  deploy =
    pkgs.writeShellScriptBin "pgrbench-deploy"
      ''
        set -euo pipefail

        set +e && nixops info -d pgrbench > /dev/null 2> /dev/null
        info=$? && set -e

        if test $info -eq 1
        then
          echo "Creating deployment..."
          nixops create deploy.nix -d pgrbench
        fi

        nixops deploy -k -d pgrbench
      '';
  info =
    pkgs.writeShellScriptBin "pgrbench-info"
      ''
        set -euo pipefail

        nixops info -d pgrbench
      '';
  k6 =
    pkgs.writeShellScriptBin "pgrbench-k6"
      ''
        set -euo pipefail
        filename=$1$(basename $2 .js)

        nixops ssh -d pgrbench client k6 run --summary-export=$filename.json -e HOST=$1 - < $2
      '';
  ssh =
    pkgs.writeShellScriptBin "pgrbench-ssh"
      ''
        set -euo pipefail

        nixops ssh -d pgrbench $1
      '';
  destroy =
    pkgs.writeShellScriptBin "pgrbench-destroy"
      ''
        set -euo pipefail

        nixops destroy -d pgrbench --confirm

        nixops delete -d pgrbench

        rm .deployment.nixops
      '';
in
pkgs.mkShell {
  buildInputs = [
    pkgs.nixops
    deploy
    info
    k6
    ssh
    destroy
  ];
  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
    export NIXOPS_STATE=".deployment.nixops"
    export PGRST_VER="nightly"
  '';
}
