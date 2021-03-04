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

Run the k6 script:

```
## k6 will run on the AWS client instance and load test the t3anano instance with the local k6/GETSingle.js script
pgrbench-k6 t3anano k6/GETSingle.js

## You will see the k6 logo and runs here
```

## Notes

- Scenarios to test:
  - [x]read heavy workload(with resource embedding)
  - [x]write heavy workload(with and without [specifying-columns](http://postgrest.org/en/v7.0.0/api.html#specifying-columns))
  - [ ]pg + pgrest on the same machine(unix socket and tcp).
  - [ ]pg and pgrest on different machines?
  - [ ]pgrest with `pre-request`?

## Other benchmarks

+ [majkinetor/postgrest-test](https://github.com/majkinetor/postgrest-test): PostgREST benchmark on Windows.
