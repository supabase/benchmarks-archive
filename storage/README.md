# `storage-api` benchmarks

Benchmarks for https://github.com/supabase/storage-api with https://k6.io/.


## Usage

```sh
# Set up Nix shell with k6.
$ nix-shell

# Run K6 on local setup.
$ k6 -e SUPABASE_URL="http://localhost:5000" -e SUPABASE_KEY="...SERVICE_KEY..." run read-buckets.js

# Run K6 on Supabase platform.
$ k6 -e SUPABASE_URL="https://PROJECT_REF.supabase.staging/storage/v1" -e SUPABASE_KEY="...SERVICE_KEY..." run read-buckets.js
```
