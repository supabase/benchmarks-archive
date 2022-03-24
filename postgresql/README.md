# PGBouncer/Postgres benchmark(Work in progress)

Updated and reproducible benchmark for PGBouncer by using [Nix](https://nixos.org/) and [sysbench](https://github.com/akopytov/sysbench/).

## Setup

The tests are ran on AWS EC2 instances on a dedicated VPC. The client(sysbench) and the servers(pg+pgbouncer) are on different instances - the collocation is similar to our current production setup.
This whole setup will be handled by Nix.

Run `nix-shell`. This will provide an environment where all the dependencies are available.

```
nix-shell
>
```

Deploy with:

```
# This assumes there's a `~/.aws/credentials` file(created with aws-cli) with a "supabase-dev" profile.
# If you want to change the profile, go to deploy.nix and edit `accessKeyId = "supabase-dev";`
pgrbench-deploy

# this command will take a couple minutes, it will deploy the client and server AWS machines VPC stuff
```

To explore and connect to the ec2 instances:

```
pgrbench-ssh t3anano

# psql -U postgres
# \d

# systemctl list-units

# top
```

You can get the ips of the instances with:

```
pgrbench-info
```

To destroy all the AWS environment:

```
pgrbench-destroy
```

## Usage

Initialize the DB:
```
pgrbench-prepare m5axlarge
```

Run the sysbench script:

```
## sysbench will run on the AWS client instance and load test the m5a.xlarge instance with 400 threads:
pgrbench-run m5axlarge 400
```
