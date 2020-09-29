# PostgREST benchmark(Work in progress)

Updated and reproducible benchmark for PostgREST by using [Nix](https://nixos.org/) and [k6](https://k6.io/).

## Setup

The tests are ran on AWS EC2 instances on a dedicated VPC. The client(k6) and the servers(pg+pgrest) are on different instances. This whole setup will be handled by Nix.

Run `nix-shell`. This will provide an environment where all the dependencies are available.

```
nix-shell
>
```

Now create the environment with nixops.

```
# This assumes there's a `~/.aws/credentials` file(created with aws-cli) with a default profile.
nixops create ./deploy.nix -d pgrst-bench

# To explore and connect to the ec2 instances
# nixops ssh -d pgrst-bench t2nano
# nixops ssh -d pgrst-bench t3anano
# nixops ssh -d pgrst-bench client
#
# you can inspect the db with
# psql -U postgres
# \d
```

## Usage

Run the k6 script:

```
## k6 will run on the aws instance
nixops ssh -d pgrst-bench client k6 run -e HOST=t3anano - < k6/GETSingle.js
```

(Steps for collecting the results are pending)

## Notes

- Scenarios to test:
  - [x]read heavy workload(with resource embedding)
  - [x]write heavy workload(with and without [specifying-columns](http://postgrest.org/en/v7.0.0/api.html#specifying-columns))
  - [ ]pg + pgrest on the same machine(unix socket and tcp).
  - [ ]pg and pgrest on different machines?
  - [ ]pgrest with `pre-request`?

## Other benchmarks

+ [majkinetor/postgrest-test](https://github.com/majkinetor/postgrest-test): PostgREST benchmark on Windows.
