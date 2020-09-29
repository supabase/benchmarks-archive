Benchmarking setup

- Install [k6](https://k6.io/docs/getting-started/installation)
- Create a [Supabase project](https://app.supabase.io/) with the following tables

```sql
-- READ DATA
create table public.read (
  id          uuid      default uuid_generate_v4()    not null primary key,
  slug        uuid      default uuid_generate_v4()
);
comment on table public.read is 'Table with some data to test read benchmarking';

-- WRITE DATA
create table public.write (
  id          uuid      default uuid_generate_v4()      not null primary key,
  slug        uuid      default uuid_generate_v4()
);
comment on table public.write is 'Table with some data to test write benchmarking';

-- BENCHMARKING-DATA
create table public.benchmarks (
  id            uuid    default uuid_generate_v4()  not null primary key,
  benchmark_name text,
  data          jsonb,
  inserted_at   timestamp with time zone    default timezone('utc'::text, now()) not null
);
comment on table public.benchmarks is 'Table to store benchmarking data';

-- BENCHMARKING SUMMARIES
create or replace view benchmark_summaries as (
  select
    id
  , benchmark_name
  , data->'metrics'->'http_reqs'->'rate' as http_reqs_rate
  , data->'metrics'->'http_reqs'->'count' as http_reqs_count
  , data->'metrics'->'http_req_duration'->'avg' as http_req_duration_avg
  , pg_size_pretty((data->'metrics'->'data_received'->'count')::bigint) as data_received
  , pg_size_pretty((data->'metrics'->'data_sent'->'count')::bigint) as data_sent
  , data->'metrics'->'vus'->'value' as vus
  , data->'metrics'->'failed requests'->'value' as failed_requests
  from
  benchmarks
);
```

Export the following environment variables before running the scripts

- supabaseKey
- supabaseUrl

Then to run all the benchmarks and upload the results to db run

> npm run benchmark
