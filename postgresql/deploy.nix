let
  region = "eu-central-1";
  accessKeyId = "supabase-dev"; ## aws profile
  sysbench = import ./sysbench.nix { stdenv = pkgs.stdenv;  fetchFromGitHub = pkgs.fetchFromGitHub ; autoreconfHook = pkgs.autoreconfHook ; pkg-config = pkgs.pkg-config ; libaio = pkgs.libaio ; postgresql = pkgs.postgresql_14; };
  env = rec {
    pgrbenchSetup = builtins.getEnv "PGRBENCH_SETUP";
    deployAll     = builtins.getEnv "PGRBENCH_DEPLOY_ALL" == "all";
  };
  pgbouncerConfigs = import ./pgbouncer.nix;
  postgresConfigs = import ./postgres.nix;

  pkgs = import <nixpkgs> {
  };
  serverConf = instanceType:
    {
      environment.systemPackages = [
        pkgs.pgbouncer
        sysbench
        pkgs.vim
      ];
      environment.etc = {
        "pgbouncer/userlist.txt" = {
          text = ''
                 "postgres" "postgres"
                 '';
        };
        "pgbouncer/pgbouncer.ini" = {
          text = ''
                 [databases]
                 * = host=localhost auth_user=pgbouncer

                 [pgbouncer]
                 listen_addr = *
                 listen_port = 6543
                 auth_file = /etc/pgbouncer/userlist.txt
                 pool_mode = transaction
                 '' + builtins.getAttr instanceType pgbouncerConfigs;
        };
      };
      systemd.services.pgbouncer = {
        enable = true;
        wantedBy = [ "machines.target" ];
        after = [ "network.target" ];
        description = "pgbouncer";
        serviceConfig = {
          Type = "simple";
          User = "postgres";
          ExecStart = "${pkgs.pgbouncer}/bin/pgbouncer /etc/pgbouncer/pgbouncer.ini";
          Restart = "on-failure";
        };
      };

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_14;
        authentication = ''
        local   all all trust
        host    all all 127.0.0.1/32 trust
        host    all all ::1/128 trust
      '';

        settings = builtins.getAttr instanceType postgresConfigs;

      };

    networking.firewall.allowedTCPPorts = [ 5432 6543 ];
  };
in {
  network.description = "pgbouncer benchmark";

  # Provisioning
  resources = {
    ec2KeyPairs.pgbouncerBenchKeyPair  = { inherit region accessKeyId; };
    # Dedicated VPC
    vpc.pgbouncerBenchVpc = {
      inherit region accessKeyId;
      name = "pgbouncer-bench-vpc";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/24";
    };
    vpcSubnets.pgbouncerBenchSubnet = {resources, ...}: {
      inherit region accessKeyId;
      name = "pgbouncer-bench-subnet";
      zone = "${region}a";
      vpcId = resources.vpc.pgbouncerBenchVpc;
      cidrBlock = "10.0.0.0/24";
      mapPublicIpOnLaunch = true;
    };
    vpcInternetGateways.pgbouncerBenchIG = { resources, ... }: {
      inherit region accessKeyId;
      name = "pgbouncer-bench-ig";
      vpcId = resources.vpc.pgbouncerBenchVpc;
    };
    vpcRouteTables.pgbouncerBenchRT = { resources, ... }: {
      inherit region accessKeyId;
      name = "pgbouncer-bench-rt";
      vpcId = resources.vpc.pgbouncerBenchVpc;
    };
    vpcRoutes.IGRoute = { resources, ... }: {
      inherit region accessKeyId;
      routeTableId = resources.vpcRouteTables.pgbouncerBenchRT;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways.pgbouncerBenchIG;
    };
    vpcRouteTableAssociations.pgbouncerBenchAssoc = { resources, ... }: {
      inherit region accessKeyId;
      subnetId = resources.vpcSubnets.pgbouncerBenchSubnet;
      routeTableId = resources.vpcRouteTables.pgbouncerBenchRT;
    };
    ec2SecurityGroups.pgbouncerBenchSecGroup = {resources, ...}: {
      inherit region accessKeyId;
      name  = "pgbouncer-bench-sec-group";
      vpcId = resources.vpc.pgbouncerBenchVpc;
      rules = [
        { fromPort = 6543;  toPort = 6543;    sourceIp = "0.0.0.0/0"; }
        { fromPort = 5432;  toPort = 5432;    sourceIp = "0.0.0.0/0"; }
        { fromPort = 22;  toPort = 22;    sourceIp = "0.0.0.0/0"; }
        { fromPort = 0;   toPort = 65535; sourceIp = resources.vpcSubnets.pgbouncerBenchSubnet.cidrBlock; } # For internal access on the VPC
      ];
    };
  };

  # m5a4xlarge =  {resources, ...}: {
  #   deployment = {
  #     targetEnv = "ec2";
  #     ec2 = {
  #       inherit region accessKeyId;
  #       instanceType             = "m5a.4xlarge";
  #       associatePublicIpAddress = true;
  #       ebsInitialRootDiskSize   = 10;
  #       keyPair                  = resources.ec2KeyPairs.pgbouncerBenchKeyPair;
  #       subnetId                 = resources.vpcSubnets.pgbouncerBenchSubnet;
  #       securityGroupIds         = [resources.ec2SecurityGroups.pgbouncerBenchSecGroup.name];
  #     };
  #   };
  #   boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  # } // serverConf "m5a.4xlarge";

  m5a2xlarge =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "m5a.2xlarge";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgbouncerBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgbouncerBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgbouncerBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  } // serverConf "m5a.2xlarge";

  # m5axlarge =  {resources, ...}: {
  #   deployment = {
  #     targetEnv = "ec2";
  #     ec2 = {
  #       inherit region accessKeyId;
  #       instanceType             = "m5a.xlarge";
  #       associatePublicIpAddress = true;
  #       ebsInitialRootDiskSize   = 10;
  #       keyPair                  = resources.ec2KeyPairs.pgbouncerBenchKeyPair;
  #       subnetId                 = resources.vpcSubnets.pgbouncerBenchSubnet;
  #       securityGroupIds         = [resources.ec2SecurityGroups.pgbouncerBenchSecGroup.name];
  #     };
  #   };
  #   boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  # } // serverConf "m5a.xlarge";

  t3amedium =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.medium";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgbouncerBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgbouncerBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgbouncerBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  } // serverConf "t3a.medium";

  client = {nodes, resources, ...}: {
    environment.systemPackages = [
      sysbench
    ];
    environment.variables = {
      PGRBENCH_SETUP = env.pgrbenchSetup;
    };
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "m5a.2xlarge";
        associatePublicIpAddress = true;
        keyPair                  = resources.ec2KeyPairs.pgbouncerBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgbouncerBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgbouncerBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1";
    # Tuning from https://k6.io/docs/misc/fine-tuning-os
    boot.kernel.sysctl."net.ipv4.tcp_tw_reuse" = 1;

    security.pam.loginLimits = [ ## ulimit -n
      { domain = "root"; type = "hard"; item = "nofile"; value = "5000"; }
      { domain = "root"; type = "soft"; item = "nofile"; value = "5000"; }
    ];
    networking.hosts = {
      # "${nodes.t3amicro.config.networking.privateIPv4}"  = [ "t3amicro" ];
      # "${nodes.t3asmall.config.networking.privateIPv4}" = [ "t3asmall" ];
      "${nodes.t3amedium.config.networking.privateIPv4}" = [ "t3amedium" ];
      # "${nodes.m5axlarge.config.networking.privateIPv4}" = [ "m5axlarge" ];
      "${nodes.m5a2xlarge.config.networking.privateIPv4}" = [ "m5a2xlarge" ];
      # "${nodes.m5a4xlarge.config.networking.privateIPv4}" = [ "m5a4xlarge" ];
    };
  };
} // {}
