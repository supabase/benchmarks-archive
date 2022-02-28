# Muliplayer latency

This is the benchmark for <https://github.com/supabase/multiplayer> with <https://k6.io>. It tests the latency between inserts in DB and events received on the multiplayer client.

## Setup

This is mainly for prod/stage setups. You should create a project on stage/prod. Add table with 2 columns: `id` (serial) and `created_at` (default value `NOW()`).

## k6

- [Install](https://k6.io/docs/getting-started/installation) k6
- Set `PG_REST_URL` to the public URL of PostgREST with created table name (ex: `https://{project_ref}.supabase.net/rest/v1/mp_latency`);
- Set `PG_REST_TOKEN` to the token for inserts via postgrest;
- Set `MP_TOKEN` to the token for multiplayer
- Set `MP_URI` to the public URL of Multiplayer instance;
- Set `RATE` to vary rate of insert actions;
- `options.duration` may be not higher then 1 minute because of current bug in MP;
- Tweak`RATE` and `options.vus` in `bench.js` to control number of connected client to MultiPlayer and rate of inserts in DB;
- Run k6.

```sh
RATE=4 k6 run k6/latency.js --summary-trend-stats="avg,med,p(99),p(95),p(0.1),p(90),p(0.01),count" --vus=5
```

# Result

<https://www.notion.so/supabase/Multiplayer-Benchmarks-bce7fce7c8bd4ea7a9a7b3ce59562d80>

# Follow Up

- Currently we're testing the latency for multiplayer and db in aws eu-central-1. Another thing we want test is different setups for infra in US, Singapore both for fly and AWS for multiplayer.
