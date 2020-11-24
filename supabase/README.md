# Supabase benchmarks

Benchmarking setup

- Install [k6](https://k6.io/docs/getting-started/installation)
- Create a [Supabase project](https://app.supabase.io/) or a Postgres Database using the migration scripts `make migrations up` 

export the following env vars from the terminal:
```bash
export SUPABASE_URL=https://<project>.supabase.net
export SUPABASE_KEY=<supabase-key>
```

Run `npm install`
Run the query from `../db/migrations/20200930011957_init.sql` on your Supabase instance to install the benchmark schema
Run the query from `../db/migrations/20201124141199_read_data.sql`, for this one you probably want to use `psql postgres://postgres:[YOUR-PASSWORD]@[SUPABASE_DB_URL]:5432/postgres -f 20201124141199_read_data.sql`

Then to run all the benchmarks and upload the results to db run

> npm run benchmark
