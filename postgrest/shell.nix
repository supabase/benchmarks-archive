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

        nixops deploy -k -d pgrbench --allow-reboot --confirm
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
        filename=$(basename $2.js)

        nixops ssh -d pgrbench client k6 run --vus $1 --summary-export=$filename.json - < $2
      '';
  clientPgBench =
    pkgs.writeShellScriptBin "pgrbench-pgbench"
      ''
        set -euo pipefail

        # uses the full cores of the instance and prepared statements
        nixops ssh -d pgrbench client pgbench example -h pg -U postgres -j 16 -T 30 -M prepared $*
      '';
  clientPgBenchVaried =
    pkgs.writeShellScriptBin "pgrbench-pgbench-varied-clients"
      ''
        set -euo pipefail

        for i in '10' '50' '100'; do
          echo -e "\n"
          pgrbench-pgbench -c $i $*
        done
      '';
  repeat =
    pkgs.writeShellScriptBin "repeat"
      ''
        set -euo pipefail

        number=$1
        shift

        for i in `seq $number`; do
          echo -e "\nRun: $i"
          $@
        done
      '';
  pgBenchAllPgInstances =
    pkgs.writeShellScriptBin "pgrbench-all-pg-instances"
      ''
        set -euo pipefail

        for instance in 'm5a.large' 'm5a.xlarge' 'm5a.2xlarge' 'm5a.4xlarge' 'm5a.8xlarge'; do
          export PGRBENCH_PG_INSTANCE_TYPE="$instance"

          pgrbench-deploy

          echo -e "\nInstance: $PGRBENCH_PG_INSTANCE_TYPE\n"
          $@
        done
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
    clientPgBench
    clientPgBenchVaried
    repeat
    pgBenchAllPgInstances
  ];
  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
    export NIXOPS_STATE=".deployment.nixops"

    export PGRBENCH_WITH_NGINX="true"
    export PGRBENCH_WITH_UNIX_SOCKET="true"
    export PGRBENCH_SEPARATE_PG="true"

    export PGRBENCH_PG_INSTANCE_TYPE="t3a.nano"
    export PGRBENCH_PGRST_INSTANCE_TYPE="t3a.nano"
    export PGRBENCH_PGRST_POOL="100"
  '';
}
