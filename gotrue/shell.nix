let
  nixpkgs = builtins.fetchTarball {
    name = "nixos-20.03";
    url = "https://github.com/nixos/nixpkgs/archive/7bc3a08d3a4c700b53a3b27f5acd149f24b931ec.tar.gz";
    sha256 = "1kiz37052zsgvw7a378zg08mpbi1wk8dkgm5j6dy0x4mxvcg8ws3";
  };
  pkgs = import nixpkgs {};
  deploy =
    pkgs.writeShellScriptBin "gotrue-deploy"
      ''
        set -euo pipefail
        set +e && nixops info -d gotrue > /dev/null 2> /dev/null
        info=$? && set -e
        if test $info -eq 1
        then
          echo "Creating deployment..."
          nixops create deploy.nix -d gotrue
        fi
        nixops deploy -k -d pgrbench --allow-reboot --confirm
      '';
  info =
    pkgs.writeShellScriptBin "gotrue-info"
      ''
        set -euo pipefail
        nixops info -d gotrue
      '';
  k6 =
    pkgs.writeShellScriptBin "gotrue-k6"
      ''
        set -euo pipefail
        nixops ssh -d gotrue client k6 run -q --vus $1 - < $2
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
  ssh =
    pkgs.writeShellScriptBin "pgrbench-ssh"
      ''
        set -euo pipefail
        nixops ssh -d pgrbench $1
      '';
  destroy =
    pkgs.writeShellScriptBin "gotrue-destroy"
      ''
        set -euo pipefail
        nixops destroy -d gotrue --confirm
        nixops delete -d gotrue
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
    repeat
  ];
  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
    export NIXOPS_STATE=".deployment.nixops"
  '';
}
