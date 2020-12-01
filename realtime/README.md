This is the benchmark for https://github.com/supabase/realtime with https://k6.io. This tests the no. of connections a Realtime instance can handle.

# Setup
We have 3 instances: one for Postgres, one for Realtime, and another for the load generator (k6). The database (Chinook) is inserted with a new value every second. The load generator creates a fixed number of WebSockets connections to Realtime. Criterion: no failed connections throughout the duration (1 minute).

## Postgres
Uses `supabase-postgres-0.13.0` AMI. Follow Usage Instructions in the AWS Marketplace page. Then:
- Run `schemas/chinook.sql`:
```sh
psql postgres://postgres:<password>@localhost/postgres -f chinook.sql
```
- Run `sql/insert.sql` once per second:
```sh
while true; do psql postgres://postgres:<password>@localhost/postgres -f insert.sql; sleep 1; done
```
## Realtime
Uses `supabase-realtime-0.7.5` AMI. Follow Usage Instructions in the AWS Marketplace page. Then:
- Set various system limits:
```sh
sudo sysctl -w fs.file-max=12000500
sudo sysctl -w fs.nr_open=20000500
ulimit -n 10000000
sudo sysctl -w net.ipv4.tcp_mem='10000000 10000000 10000000'
sudo sysctl -w net.ipv4.tcp_rmem='1024 4096 16384'
sudo sysctl -w net.ipv4.tcp_wmem='1024 4096 16384'
sudo sysctl -w net.core.rmem_max=16384
sudo sysctl -w net.core.wmem_max=16384
```
- Add a line in `[Service]` in `/etc/systemd/system/realtime.service`:
```ini
[Service]
...
LimitNOFILE=214783584
```
- Delete log, restart Realtime:
```sh
sudo rm /var/log/realtime.stdout
sudo systemctl daemon-reload
sudo systemctl restart realtime
```
- Watch log:
```sh
tail -f /var/log/realtime.stdout
```
## k6
- Set system limits as in Realtime
- [Install](https://k6.io/docs/getting-started/installation) k6
- Set `REALTIME_URL` to the public IP of Realtime
- Tweak `options.duration` and `options.vus` in `bench.js` 
- Run k6:
```sh
k6 run bench.js
```

# Result
- t2.nano: ~1000 connections
- t3a.micro: ~5000 connections
- t3a.xlarge: ~10000 connections

The main bottleneck seems to be neither CPU nor memory. At the thresholds above, the CPU floats around 40%. Memory is only ever a problem in t2.nano.

Increasing the no. of connections will lead to these errors:

```
ERRO[0030] GoError: unexpected EOF
running at github.com/loadimpact/k6/js/common.Bind.func1 (native)
default at file:///home/ubuntu/script.js:12:39(8)  executor=constant-vus scenario=default source=stacktrace
```

```
ERRO[0083] GoError: read tcp 172.31.29.119:41778->13.229.116.108:4000: i/o timeout
default at github.com/loadimpact/k6/js/common.Bind.func1 (native)
	at file:///home/ubuntu/script.js:12:39(8)  executor=constant-vus scenario=default source=stacktrace
```

Counting the number of connections in Realtime, e.g. with `ss -tn src :4000 | wc -l`, during the benchmark suggests some connections from the load generator are unsuccessful (usually around 10%). Looking at the numbers, we should be able to handle 2x the no. of connections if we can eliminate this I/O issue.

# Follow Up
- Currently we're testing the no. of connections for one Realtime instance. Another thing we can test is the no. of events (throughput).
