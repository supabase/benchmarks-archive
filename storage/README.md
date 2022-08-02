# `storage-api` benchmarks

Benchmarks for https://github.com/supabase/storage-api with https://k6.io/.

## Usage

```sh
# Set up Nix shell with k6.
$ nix-shell

# Run K6 on local setup.
$ k6 run -e SUPABASE_URL="http://localhost:5000" -e SUPABASE_KEY="...SERVICE_KEY..." read-buckets.js

# Run K6 on Supabase platform.
$ k6 run -e SUPABASE_URL="https://PROJECT_REF.supabase.staging/storage/v1" -e SUPABASE_KEY="...SERVICE_KEY..." read-buckets.js
```

## Benchmarks

- read-buckets.js
- read-object.js
- upload-object.js
  ```shell
  $ k6 run -e OBJECT_SIZE="100kib/1mib/10mib" -e SUPABASE_URL="http://localhost:5000" -e SUPABASE_KEY="...SERVICE_KEY..." upload-object.js
  ```
