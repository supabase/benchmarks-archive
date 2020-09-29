let
  region = "us-east-2";
  accessKeyId = "default"; ## aws profile
  pkgs = import <nixpkgs> {};
  serverConf = let pgrst = import ./pgrst.nix { stdenv = pkgs.stdenv; fetchurl = pkgs.fetchurl; }; in
  {
    environment.systemPackages = [
      pgrst
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_12;
      authentication = pkgs.lib.mkOverride 10 ''
        local   all all trust
        host    all all 127.0.0.1/32 trust
        host    all all ::1/128 trust
      '';
      initialScript = ./sql/chinook.sql; # Here goes the sample db
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

  # Configuration
  t2nano = {resources, ...}: {
    deployment = {
      targetEnv = "ec2";
      ec2 = {
        inherit region accessKeyId;
        instanceType             = "t2.nano";
        associatePublicIpAddress = true;
        ebsInitialRootDiskSize   = 10;
        keyPair                  = resources.ec2KeyPairs.pgrstBenchKeyPair;
        subnetId                 = resources.vpcSubnets.pgrstBenchSubnet;
        securityGroupIds         = [resources.ec2SecurityGroups.pgrstBenchSecGroup.name];
      };
    };
  } // serverConf;

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
    networking.hosts ={
      "${nodes.t2nano.config.networking.privateIPv4}"  = [ "t2nano" ];
      "${nodes.t3anano.config.networking.privateIPv4}" = [ "t3anano" ];
    };
  };
}
