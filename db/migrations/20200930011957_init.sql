-- migrate:up
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- READ DATA
CREATE TABLE public.read (
  id bigserial PRIMARY KEY,
  slug int
);

-- READ SINGLE DATA
CREATE TABLE public.readsingle (
  id bigserial PRIMARY KEY,
  slug int
);

COMMENT ON TABLE public.read IS 'Table with some data to test read benchmarking';

-- WRITE DATA
CREATE TABLE public.write (
  id bigserial PRIMARY KEY,
  slug int
);

COMMENT ON TABLE public.write IS 'Table with some data to test write benchmarking';

-- BENCHMARKING-DATA
CREATE TABLE public.benchmarks (
  id uuid DEFAULT extensions.uuid_generate_v4 () NOT NULL PRIMARY KEY,
  benchmark_name text,
  data jsonb,
  inserted_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

COMMENT ON TABLE public.benchmarks IS 'Table to store benchmarking data';

-- BENCHMARKING SUMMARIES
CREATE OR REPLACE VIEW benchmark_summaries AS (
  SELECT
    id,
    benchmark_name,
    data -> 'metrics' -> 'http_reqs' -> 'rate' AS http_reqs_rate,
    data -> 'metrics' -> 'http_reqs' -> 'count' AS http_reqs_count,
    data -> 'metrics' -> 'http_req_duration' -> 'avg' AS http_req_duration_avg,
    pg_size_pretty((data -> 'metrics' -> 'data_received' -> 'count')::bigint) AS data_received,
    pg_size_pretty((data -> 'metrics' -> 'data_sent' -> 'count')::bigint) AS data_sent,
    data -> 'metrics' -> 'vus' -> 'value' AS vus,
    data -> 'metrics' -> 'failed requests' -> 'value' AS failed_requests
  FROM
    benchmarks);

-- migrate:down
