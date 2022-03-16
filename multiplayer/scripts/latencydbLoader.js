import sql from 'k6/x/sql';
import { sleep } from 'k6';
import { Counter } from 'k6/metrics';

const pgUser = __ENV.PG_USER || 'postgres';
const pgPass = __ENV.PG_PASS;
const pgDB = __ENV.PG_DB || 'postgres';
const pgPort = __ENV.PG_PORT || '6543';
const pgHost = __ENV.PG_HOST || 'db.hcsnoerwwpaigmizfxmg.supabase.net';
const pdConnectionString = `postgres://${pgUser}:${pgPass}@${pgHost}:${pgPort}/${pgDB}?sslmode=disable`;
const db = sql.open('postgres', pdConnectionString);

const rate = __ENV.RATE || 2;

const counterInserts = new Counter('inserts');
const virtualUsers = 1;

export const options = {
  duration: '4m',
  vus: virtualUsers,
};

/**
 * Create a table called "mp_latency" for testing if it doesn't exist,
 * and if it does exist, do nothing
 */
export function setup() {
  db.exec(`create table if not exists "mp_latency" (
    id bigserial primary key,
    created_at timestamptz default now() NOT NULL
  );`);
}

/**
 * Close the database connection
 */
export function teardown() {
  db.close();
}

export default () => {
  db.exec('insert into mp_latency default values;');
  counterInserts.add(1);
  sleep(1 / rate);
};