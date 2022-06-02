let
  pkgs = import <nixpkgs> {};
  region = "us-east-2";
  accessKeyId = "default"; ## aws profile
  env = {
    withNginx         = builtins.getEnv "PGRBENCH_WITH_NGINX" == "true";
    withUnixSocket    = builtins.getEnv "PGRBENCH_WITH_UNIX_SOCKET" == "true";
    withSeparatePg    = builtins.getEnv "PGRBENCH_SEPARATE_PG" == "true";
    withNgnixLBS      = builtins.getEnv "PGRBENCH_PGRST_NGNIX_LBS" == "true";

    pgInstanceType    = builtins.getEnv "PGRBENCH_PG_INSTANCE_TYPE";
    pgrstInstanceType = builtins.getEnv "PGRBENCH_PGRST_INSTANCE_TYPE";
    pgrstPool         = builtins.getEnv "PGRBENCH_PGRST_POOL";

    withPgLogging     =
      pkgs.lib.optionalAttrs (builtins.getEnv "PGRBENCH_PG_LOGGING" == "true") {
        logging_collector = "on";
        log_directory = "pg_log";
        log_filename = "postgresql-%Y-%m-%d.log";
        log_statement = "all";
      };
  };
  postgresConfigs = import ../postgresql/postgres.nix;
in {
  network.description = "postgrest benchmark";

  # Provisioning
  resources = {
    ec2KeyPairs.pgrstBenchKeyPair  = { inherit region accessKeyId; };
    # Dedicated VPC
    vpc.pgrstBenchVpc = {
      inherit region accessKeyId;
      name = "pgrst-bench-vpc";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/24";
    };
    vpcSubnets.pgrstBenchSubnet = {resources, ...}: {
      inherit region accessKeyId;
      name = "pgrst-bench-subnet";
      zone = "${region}a";
      vpcId = resources.vpc.pgrstBenchVpc;
      cidrBlock = "10.0.0.0/24";
      mapPublicIpOnLaunch = true;
    };
    vpcInternetGateways.pgrstBenchIG = { resources, ... }: {
      inherit region accessKeyId;
      name = "pgrst-bench-ig";
      vpcId = resources.vpc.pgrstBenchVpc;
    };
    vpcRouteTables.pgrstBenchRT = { resources, ... }: {
      inherit region accessKeyId;
      name = "pgrst-bench-rt";
      vpcId = resources.vpc.pgrstBenchVpc;
    };
    vpcRoutes.IGRoute = { resources, ... }: {
      inherit region accessKeyId;
      routeTableId = resources.vpcRouteTables.pgrstBenchRT;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways.pgrstBenchIG;
    };
    vpcRouteTableAssociations.pgrstBenchAssoc = { resources, ... }: {
      inherit region accessKeyId;
      subnetId = resources.vpcSubnets.pgrstBenchSubnet;
      routeTableId = resources.vpcRouteTables.pgrstBenchRT;
    };
    ec2SecurityGroups.pgrstBenchSecGroup = {resources, ...}: {
      inherit region accessKeyId;
      name  = "pgrst-bench-sec-group";
      vpcId = resources.vpc.pgrstBenchVpc;
      rules = [
        { fromPort = 80;  toPort = 80;    sourceIp = "0.0.0.0/0"; }
        { fromPort = 22;  toPort = 22;    sourceIp = "0.0.0.0/0"; }
        # protocol -1 allows icmp traffic in addition to tcp/udp
        { protocol = "-1"; fromPort = 0;   toPort = 65535; sourceIp = resources.vpcSubnets.pgrstBenchSubnet.cidrBlock; } # For internal access on the VPC
      ];
    };
  };

  pgrstServer = {nodes, config, resources, ...}: let pgrst = pkgs.callPackage ./pgrst.nix {}; in
  {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             =
          if builtins.stringLength env.pgrstInstanceType == 0
          then "t3a.nano"
          else env.pgrstInstanceType;
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379

    environment.systemPackages = [
      pgrst
      pkgs.htop
    ];

    services.postgresql = pkgs.lib.mkIf (!env.withSeparatePg) {
      enable = true;
      package = pkgs.postgresql_12;
      authentication = ''
        local   all all trust
        host    all all 127.0.0.1/32 trust
        host    all all ::1/128 trust
        host    all all ${resources.vpcSubnets.pgrstBenchSubnet.cidrBlock} trust
      '';
      enableTCPIP = true; # listen_adresses = *
      # Tuned according to https://pgtune.leopard.in.ua
      settings = builtins.getAttr config.deployment.ec2.instanceType postgresConfigs // env.withPgLogging;
      initialScript = ../schemas/chinook/chinook.sql; # Here goes the sample db
    };

    systemd.services.postgrest = {
      enable      = true;
      description = "postgrest daemon";
      after       = [ "postgresql.service" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart =
          let
            pgHost =
              if env.withSeparatePg then "pg"
              else if env.withUnixSocket then ""
              else "localhost";
            pgrstConf = pkgs.writeText "pgrst.conf" ''
              db-uri = "postgres://postgres@${pgHost}/postgres"
              db-schema = "public"
              db-anon-role = "postgres"
              db-use-legacy-gucs = false
              db-pool = ${if builtins.stringLength env.pgrstPool == 0 then "20" else env.pgrstPool}
              db-pool-timeout = 3600

              ${
                if env.withNginx && env.withUnixSocket
                then ''
                  server-unix-socket = "/tmp/pgrst.sock"
                  server-unix-socket-mode = "777"
                ''
                else if env.withNginx
                then ''
                  server-port = "3000"
                ''
                else ''
                  server-port = "80"
                ''
              }

              jwt-secret = "reallyreallyreallyreallyverysafe"
            '';
          in
          "${pgrst}/bin/postgrest ${pgrstConf}";
        Restart = "always";
      };
    };
    systemd.services.postgrst = {
      enable      = if env.withNgnixLBS then true else false;
      description = "postgrst daemon";
      after       = [ "postgresql.service" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart =
          let
            pgHost =
              if env.withSeparatePg then "pg"
              else if env.withUnixSocket then ""
              else "localhost";
            pgrstConf = pkgs.writeText "pgrst2.conf" ''
              db-uri = "postgres://postgres@${pgHost}/postgres"
              db-schema = "public"
              db-anon-role = "postgres"
              db-use-legacy-gucs = false
              db-pool = ${if builtins.stringLength env.pgrstPool == 0 then "20" else env.pgrstPool}
              db-pool-timeout = 60

              ${
                if env.withNginx && env.withUnixSocket
                then ''
                  server-unix-socket = "/tmp/pgrst_1.sock"
                  server-unix-socket-mode = "777"
                ''
                else if env.withNginx
                then ''
                  server-port = "3000"
                ''
                else ''
                  server-port = "80"
                ''
              }

              jwt-secret = "reallyreallyreallyreallyverysafe"
            '';
          in
	  "${pgrst}/bin/postgrest ${pgrstConf}";
        Restart = "always";
      };
    };

    services.nginx = {
      enable = env.withNginx;
      config = ''
        events {}

        http {
          upstream postgrest {
            ${
              if env.withUnixSocket && env.withNgnixLBS
              then ''
                server unix:/tmp/pgrst.sock;
                server unix:/tmp/pgrst_1.sock;
              ''
              else if env.withUnixSocket
              then
              ''
                server unix:/tmp/pgrst.sock;
              ''
              else ''
                server localhost:3000;
              ''

            }
            keepalive 64;
            keepalive_timeout 120s;
          }

          server {
            listen 80 default_server;
            listen [::]:80 default_server;

            location / {
              proxy_set_header  Connection "";
              proxy_set_header  Accept-Encoding  "";
              proxy_http_version 1.1;
              proxy_pass http://postgrest/;
            }
          }
        }
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 5432 ];
    networking.hosts = pkgs.lib.optionalAttrs env.withSeparatePg {
      "${nodes.pg.config.networking.privateIPv4}" = [ "pg" ];
    };
  };

  client = {nodes, resources, ...}: {
    environment.systemPackages = [
      pkgs.k6
      pkgs.postgresql_12 # only used for getting pgbench, no postgresql is started here
    ];
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "m5a.16xlarge";
        associatePublicIpAddress = true;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1";
    # Tuning from https://k6.io/docs/misc/fine-tuning-os
    boot.kernel.sysctl."net.ipv4.tcp_tw_reuse" = 1;
    security.pam.loginLimits = [ ## ulimit -n
      { domain = "root"; type = "hard"; item = "nofile"; value = "10000"; }
      { domain = "root"; type = "soft"; item = "nofile"; value = "10000"; }
    ];
    networking.hosts = {
      "${nodes.pgrstServer.config.networking.privateIPv4}" = [ "pgrst" ];
    } // pkgs.lib.optionalAttrs env.withSeparatePg {
      "${nodes.pg.config.networking.privateIPv4}" = [ "pg" ];
    };
  };
}
// pkgs.lib.optionalAttrs env.withSeparatePg
{
  pg = {resources, config, ...}: rec {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             =
          if builtins.stringLength env.pgInstanceType == 0
          then "t3a.nano"
          else env.pgInstanceType;
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_12;
      authentication = ''
        local   all all trust
        host    all all 127.0.0.1/32 trust
        host    all all ::1/128 trust
        host    all all ${resources.vpcSubnets.pgrstBenchSubnet.cidrBlock} trust
      '';
      enableTCPIP = true; # listen_adresses = *
      # Tuned according to https://pgtune.leopard.in.ua
      settings = builtins.getAttr config.deployment.ec2.instanceType postgresConfigs // env.withPgLogging;
      initialScript = ../schemas/chinook/chinook.sql; # Here goes the sample db
    };

    networking.firewall.allowedTCPPorts = [ 5432 ];
  };
}
