import sql from 'k6/x/sql';
import { sleep } from 'k6';
import { Counter } from 'k6/metrics';

// Database connection
const pgUser = __ENV.PG_USER || 'postgres';
const pgPass = __ENV.PG_PASS || '';
const pgDB = __ENV.PG_DB || 'postgres';
const pgPort = __ENV.PG_PORT || '5432';
const pgHost = __ENV.PG_HOST || '';
const pdConnectionString = `postgres://${pgUser}:${pgPass}@${pgHost}:${pgPort}/${pgDB}?sslmode=disable`;

const db = sql.open('postgres', pdConnectionString);

const user = `NoKNwRWgDz${Math.random().toString(36).slice(2)}`
const room = `zSbFOs3ccOh09yIf1-W${getRandomInt(0, 30)}`

// Test params
// rate - number of inserts per second (separate transactions)
const rate = __ENV.RATE || 2;
// test duration
const duration = __ENV.DURATION || 60;

// reports
const counterInserts = new Counter('inserts');

let virtualUsers = 1;
if (rate >= 5) {
  virtualUsers = 5;
}
if (rate >= 20) {
  virtualUsers = 10;
}
if (rate > 50) {
  virtualUsers = 15;
}
// test options
export const options = {
  duration: `${duration}s`,
  vus: virtualUsers,
};

/**
 * Close the database connection
 */
export function teardown() {
  db.close();
}

export default () => {
  let rand = 0;
  if (virtualUsers > 1) {
    rand = getRandomInt(0, virtualUsers);
    sleep(rand / rate);
  }
  // send inserts to the database
  const start = new Date();
  db.exec(`insert into messages(user_id, room_id, message) values ('${user}', '${room}', '${Math.random().toString(36).slice(2)}');`);
  const finish = new Date();
  counterInserts.add(1);
  sleep((virtualUsers - rand) / rate - (finish - start) / 1000);
};

/**
 * Return a random integer between the minimum (inclusive)
 * and maximum (exclusive) values
 * @param {number} min - The minimum value to return.
 * @param {number} max - The maximum value you want to return.
 * @return {number} The random number between the min and max.
 */
function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  // The maximum is exclusive and the minimum is inclusive
  return Math.floor(Math.random() * (max - min) + min);
}