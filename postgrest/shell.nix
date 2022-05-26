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

        nixops ssh -d pgrbench client k6 run -q --vus $1 - < $2
      '';
  k6VariedVus =
    pkgs.writeShellScriptBin "pgrbench-k6-varied-vus"
      ''
        set -euo pipefail

        for i in '10' '50' '100'; do
          echo -e "\n"
          pgrbench-k6 $i $1
        done
      '';
  clientPgBench =
    pkgs.writeShellScriptBin "pgrbench-pgbench"
      ''
        set -euo pipefail

        host=$([ "$PGRBENCH_SEPARATE_PG" = "true" ] && echo "pg" || echo "pgrst")
        # uses the full cores of the instance and prepared statements
        nixops ssh -d pgrbench client pgbench postgres -h $host -U postgres -j 16 -T 30 -c $1 --no-vacuum -f - < $2
      '';
  clientPgBenchVaried =
    pkgs.writeShellScriptBin "pgrbench-pgbench-varied-clients"
      ''
        set -euo pipefail

        for i in '10' '50' '100'; do
          echo -e "\n"
          pgrbench-pgbench $i $1
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
  pgBenchAllPgPgrestInstances =
    pkgs.writeShellScriptBin "pgrbench-all-pg-pgrest-instances"
      ''
        set -euo pipefail

        counter=0

        for instance in 'm5a.large' 'm5a.xlarge' 'm5a.2xlarge' 'm5a.4xlarge' 'm5a.8xlarge' 'm5a.12xlarge' 'm5a.16xlarge'; do
          export PGRBENCH_PG_INSTANCE_TYPE="$instance"
          export PGRBENCH_PGRST_INSTANCE_TYPE="$instance"
          export PGRBENCH_PGRST_POOL=$((100 + counter*50))

          counter=$((counter + 1))

          pgrbench-deploy

          sleep 2s # TODO: sleep until pgrest establishes a connection to pg, this should be handled in a k6 setup

          echo -e "\nPostgreSQL instance: $PGRBENCH_PG_INSTANCE_TYPE\n"
          echo -e "PostgREST instance: $PGRBENCH_PGRST_INSTANCE_TYPE\n"
          echo -e "PostgREST Pool: $PGRBENCH_PGRST_POOL\n"
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
    k6VariedVus
    ssh
    destroy
    clientPgBench
    clientPgBenchVaried
    repeat
    pgBenchAllPgInstances
    pgBenchAllPgPgrestInstances
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

    export PGRBENCH_PG_LOGGING="false"
  '';
}
