# GoTrue benchmark(Work in progress)

Updated and reproducible benchmark for GoTrue by using [Nix](https://nixos.org/) and [k6](https://k6.io).

## Setup

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

```

## Usage
TODO 
    
