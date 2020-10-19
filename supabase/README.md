# Supabase benchmarks

Benchmarking setup

- Install [k6](https://k6.io/docs/getting-started/installation)
- Create a [Supabase project](https://app.supabase.io/) or a Postgres Database using the migration scripts `make migrations up` 

export the following env vars from the terminal:
```bash
export supabaseUrl=https://<project>.supabase.net
export supabaseKey=<supabase-key>
```

Then to run all the benchmarks and upload the results to db run

> npm run benchmark
