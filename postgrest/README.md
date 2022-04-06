# PostgREST benchmark(Work in progress)

Updated and reproducible benchmark for PostgREST by using [Nix](https://nixos.org/) and [k6](https://k6.io/).

## Setup

The tests are ran on AWS EC2 instances on a dedicated VPC. The client(k6) and the servers(pg+pgrest) are on different instances.
This whole setup will be handled by Nix.

Run `nix-shell`. This will provide an environment where all the dependencies are available.

```
nix-shell
>
```

Deploy with:

```
# This assumes there's a `~/.aws/credentials` file(created with aws-cli) with a "default" profile.
# If you want to change the "default" profile, go to deploy.nix and edit `accessKeyId = "default";`
pgrbench-deploy

# this command will take a couple minutes, it will deploy the client and server AWS machines VPC stuff
```

To explore and connect to the ec2 instances:

```
pgrbench-ssh pgrstServer

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

Run the k6 script:

```
## k6 will run on the AWS client instance and load test the t3anano instance with the local k6/GETSingle.js script
pgrbench-k6 t3anano k6/GETSingle.js

## You will see the k6 logo and runs here
```

## Nginx

To load test with nginx included do:

```bash
export PGRBENCH_WITH_NGINX="true"
pgrbench-deploy
```

## Unix socket(default)

To load test connecting pgrest to pg with unix socket, and pgrest to nginx with unix socket.

```bash
export PGRBENCH_WITH_UNIX_SOCKET="true"
pgrbench-deploy
```

To use tcp instead, you can do:

```bash
export PGRBENCH_WITH_UNIX_SOCKET="false"
pgrbench-deploy
```

## Separate PostgreSQL

To load test with a pg on a different ec2 instance.

```bash
export PGRBENCH_SEPARATE_PG="true"
pgrbench-deploy
```

## Change EC2 instance types

To change pg and PostgREST EC2 instance types(both t3a.nano by default):

```bash
export PGRBENCH_PG_INSTANCE_TYPE="t3a.xlarge"
export PGRBENCH_PGRST_INSTANCE_TYPE="t3a.xlarge"

pgrbench-deploy
```

Don't try with ARM-based instances, these don't work currently for NixOps.

## Scenarios to test

- [x]read heavy workload(with resource embedding)
- [x]write heavy workload
- [x]pg + pgrest on the same ec2 instance(unix socket and tcp).
- [x]pg + pgrest + nginx on the same ec2 instance
- [x]pg and pgrest(w/o nginx) on separate ec2 instance
- [x]separate pg with different type of ec2 instances and tuned with https://pgtune.leopard.in.ua/#/
- [ ]pgrest with `pre-request`
- [ ]insertions with [specifying-columns](http://postgrest.org/en/v7.0.0/api.html#specifying-columns)
- [ ]a slow rpc with `pg_sleep`

## Other benchmarks

+ [majkinetor/postgrest-test](https://github.com/majkinetor/postgrest-test): PostgREST benchmark on Windows.
