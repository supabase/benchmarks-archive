# Muliplayer latency

This is the benchmark for <https://github.com/supabase/multiplayer> with <https://k6.io>. It tests the latency between inserts in DB and events received on the multiplayer client.

## Setup

This is mainly for prod/stage setups. You should create a project on stage/prod. Add table with 2 columns: `id` (serial) and `created_at` (default value `NOW()`).

## k6

- [Install](https://k6.io/docs/getting-started/installation) k6

1. Load via PostgREST

- Set `PG_REST_URL` to the public URL of PostgREST with created table name (ex: `https://{project_ref}.supabase.net/rest/v1/mp_latency`);
- Set `PG_REST_TOKEN` to the token for inserts via postgrest;
- Set `MP_TOKEN` to the token for multiplayer
- Set `MP_URI` to the public URL of Multiplayer instance;
- Set `RATE` to vary rate of insert actions;
- `options.duration` may be not higher then 1 minute because of current bug in MP;
- Tweak`RATE` and `options.vus` in `bench.js` to control number of connected client to MultiPlayer and rate of inserts in DB;
- Run k6.

```sh
RATE=4 k6 run scripts/latency.js --summary-trend-stats="avg,med,p(99),p(95),p(0.1),p(90),p(0.01),count" --vus=5
```

2. Load via DataBase

- Install `golang`
- Install xk6 `go install go.k6.io/xk6/cmd/xk6@latest`
- Build the binary: `xk6 build master --with github.com/grafana/xk6-sql`
- Set `PG_USER` to the username in postgresql server; default: `postgres`;
- Set `PG_PASS` to the password for postgresql server;
- Set `PG_DB` to the database in postgresql server; default: `postgres`;
- Set `PG_PORT` to the port of postgresql server; default: `6543`;
- Set `PG_HOST` to the host address of postgresql server; default: `localhost`;
- Set `MP_TOKEN` to the token for multiplayer
- Set `MP_URI` to the public URL of Multiplayer instance; ex: `ws://{proj_ref}.multiplayer.red/socket/websocket`
- Set `DURATION` to vary duration of load (note actual load is going to start 60 sec after subscribers start to connect);
- Set `RATE` to vary rate of insert actions;
- Tweak`RATE` on `latencydbLoader.js` and `--vus` in `latencydbSubs.js` to control number of connected clients to MultiPlayer and rate of inserts in DB;
- Run locally built k6.

```sh
make delay=60 rate=20 conns=100 db_test
```

Tweak `rate` and `conns` in the command. delay depends on conns number and should be around 60 (sec) for 200 users.

3. Load Demo project in fly

Everything is just like in the 2.

But command is the following

```sh
make delay=60 rate=20 conns=100 demo_test
```

# Result

<https://www.notion.so/supabase/Multiplayer-Benchmarks-bce7fce7c8bd4ea7a9a7b3ce59562d80>

# Follow Up

- Currently we're testing the latency for multiplayer and db in aws eu-central-1. Another thing we want test is different setups for infra in US, Singapore both for fly and AWS for multiplayer.
