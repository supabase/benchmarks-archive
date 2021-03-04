let
  region = "us-east-2";
  accessKeyId = "default"; ## aws profile
  deployAll = builtins.getEnv "PGRBENCH_DEPLOY_ALL" == "all";
  pgrstNightly = builtins.getEnv "PGRST_VER" == "nightly";
  pkgs = import <nixpkgs> {};
  serverConf =
  let pgrst = import ./pgrst.nix { stdenv = pkgs.stdenv; fetchurl = pkgs.fetchurl; isNightly = pgrstNightly; }; in
  {
    environment.systemPackages = [
      pgrst
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_12;
      authentication = ''
        local   all all trust
        host    all all 127.0.0.1/32 trust
        host    all all ::1/128 trust
      '';
      initialScript = ../schemas/chinook/chinook.sql; # Here goes the sample db
    };

    systemd.services.postgrest = {
      enable      = true;
      description = "postgrest daemon";
      after       = [ "postgresql.service" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart =
          let pgrstConf = pkgs.writeText "pgrst.conf" ''
            db-uri = "postgres://postgres@localhost/postgres"
            db-schema = "public"
            db-anon-role = "postgres"

            server-port = 80

            jwt-secret = "reallyreallyreallyreallyverysafe"
          '';
          in
          "${pgrst}/bin/postgrest ${pgrstConf}";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
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
        { fromPort = 0;   toPort = 65535; sourceIp = resources.vpcSubnets.pgrstBenchSubnet.cidrBlock; } # For internal access on the VPC
      ];
    };
  };

  t3anano = {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.nano";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  } // serverConf;

  client = {nodes, resources, ...}: {
    environment.systemPackages = [
      pkgs.k6
    ];
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.medium";
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
      { domain = "root"; type = "hard"; item = "nofile"; value = "5000"; }
      { domain = "root"; type = "soft"; item = "nofile"; value = "5000"; }
    ];
    networking.hosts = {
      "${nodes.t3anano.config.networking.privateIPv4}"   = [ "t3anano" ];
    } // pkgs.lib.optionalAttrs deployAll {
      "${nodes.t3amicro.config.networking.privateIPv4}"  = [ "t3amicro" ];
      "${nodes.t3amedium.config.networking.privateIPv4}" = [ "t3amedium" ];
      "${nodes.t3alarge.config.networking.privateIPv4}"  = [ "t3alarge" ];
      "${nodes.t3axlarge.config.networking.privateIPv4}" = [ "t3axlarge" ];
      "${nodes.c5xlarge.config.networking.privateIPv4}"  = [ "c5xlarge" ];
    };
  };
} //
pkgs.lib.optionalAttrs deployAll
{
  t3amicro =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.micro";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  } // serverConf;

  t3amedium =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.medium";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1"; # Fix for https://github.com/NixOS/nixpkgs/issues/62824#issuecomment-516369379
  } // serverConf;

  t3alarge =  {resources, ...}:  {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.large";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1";
  } // serverConf;

  t3axlarge =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t3a.xlarge";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
    boot.loader.grub.device = pkgs.lib.mkForce "/dev/nvme0n1";
  } // serverConf;

  c5xlarge =  {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "c5.xlarge";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
  } // serverConf;
}
