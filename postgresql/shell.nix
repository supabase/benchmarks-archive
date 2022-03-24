let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-21.11";
    url = "https://github.com/nixos/nixpkgs/archive/6a395040caf5489950830b1871c11ff1657302a7.tar.gz";
    # sha256 = "1kiz37052zsgvw7a378zg08mpbi1wk8dkgm5j6dy0x4mxvcg8ws3";
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
  prepare =
    pkgs.writeShellScriptBin "pgrbench-prepare"
      ''
        set -euo pipefail
        filename=$1-prepare.log

        nixops ssh -d pgrbench client sysbench oltp_read_write prepare --pgsql-user=postgres --pgsql-db=postgres --time=20 --threads=10 --report-interval=1 --tables=10 --pgsql-password=postgres --db-driver=pgsql --pgsql-host=$1 --pgsql-port=6543 | tee $filename
      '';
  run =
    pkgs.writeShellScriptBin "pgrbench-run"
      ''
        set -euo pipefail
        filename=$1-$2-threads-run.log

        nixops ssh -d pgrbench client sysbench oltp_read_write run --pgsql-user=postgres --pgsql-db=postgres --time=20 --threads=$2 --report-interval=1 --tables=10 --pgsql-password=postgres --db-driver=pgsql --pgsql-host=$1 --pgsql-port=6543 --db-ps-mode=disable | tee $filename
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
    prepare
    run
    ssh
    destroy
  ];
  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
    export NIXOPS_STATE=".deployment.nixops"
  '';
}
