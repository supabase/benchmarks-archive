Benchmarking setup

- Install [k6](https://k6.io/docs/getting-started/installation)
- Create a [Supabase project](https://app.supabase.io/) with the following tables

```sql
-- READ DATA
create table public.read (
  id          uuid          not null primary key,
  slug        text
);
comment on table public.read is 'Table with some data to test read benchmarking';

-- WRITE DATA
create table public.write (
  id          uuid          not null primary key,
  slug        text
);
comment on table public.write is 'Table with some data to test write benchmarking';

-- BENCHMARKING-DATA
create table public.benchmarks (
  id            uuid                        not null primary key,
  benchmark_name text,
  data          jsonb,
  inserted_at   timestamp with time zone    default timezone('utc'::text, now()) not null
);
comment on table public.benchmarks is 'Table to store benchmarking data';
```

Export the following environment variables before running the scripts

- supabaseKey
- supabaseUrl

Then to run all the benchmarks and upload the results to db run

> npm run benchmark
