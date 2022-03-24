import {check} from 'k6';
import ws from 'k6/ws';
import sql from 'k6/x/sql';
import {Trend, Counter} from 'k6/metrics';

// Realtime connection
// eslint-disable-next-line max-len
const token = __ENV.MP_TOKEN || '';
const socketURI = __ENV.MP_URI || 'ws://hcsnoerwwpaigmizfxmg.multiplayer.red/socket/websocket';
const URL = `${socketURI}?apikey=${token}`;

// Database connection
const pgUser = __ENV.PG_USER || 'postgres';
const pgPass = __ENV.PG_PASS || '';
const pgDB = __ENV.PG_DB || 'postgres';
const pgPort = __ENV.PG_PORT || '6543';
const pgHost = __ENV.PG_HOST || 'db.hcsnoerwwpaigmizfxmg.supabase.net';
const pdConnectionString = `postgres://${pgUser}:${pgPass}@${pgHost}:${pgPort}/${pgDB}?sslmode=disable`;

const db = sql.open('postgres', pdConnectionString);

// Test params
// rate - number of inserts per second (separate transactions)
const rate = __ENV.RATE || 2;
// test duration
const duration = __ENV.DURATION || 60;

// reports
const latencyTrend = new Trend('latency_trend');
const counterInserts = new Counter('inserts');
const counterReceived = new Counter('received_updates');

// thresholds is a workaround to get total number of received events per second
const to = {};
const started = Math.floor((new Date()).getTime() / 1000);
for (let i = 0; i < duration+10; i++) {
  to[`received_updates{timeMark:${started + i}}`] = ['count>=0'];
}

// test options
export const options = {
  duration: `${duration}s`,
  vus: 1,
  thresholds: to,
  summaryTrendStats: ['avg', 'med', 'p(99)', 'p(95)', 'p(0.1)', 'count'],
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
  const res = ws.connect(URL, {}, (socket) => {
    socket.on('open', () => {
      // Join channel
      socket.send(JSON.stringify({
        topic: 'realtime:*',
        event: 'phx_join',
        payload: {user_token: token},
        ref: 0,
      }));
      socket.setInterval(() => {
        // Send heartbeat to server (timeout is probably around 1m)
        socket.send(JSON.stringify({
          topic: 'phoenix',
          event: 'heartbeat',
          payload: {},
          ref: 0,
        }));
      }, 30 * 1000);
      // send inserts to the database
      socket.setInterval(() => {
        if (getRandomInt(0, options.vus) !== 0) {
          return;
        }
        db.exec('insert into mp_latency default values;');
        counterInserts.add(1);
      }, Math.ceil(1000 / rate));
    });

    socket.on('message', (msg) => {
      const now = new Date();
      // console.log('----------------');
      // console.log(msg);
      // console.log('----------------');
      msg = JSON.parse(msg);
      if (msg.event === 'phx_reply') {
        return;
      }

      const type = msg.payload.type;
      let updated = 0;
      if (msg.payload.record) {
        updated = new Date(msg.payload.record.created_at);
      } else {
        updated = new Date(msg.payload.commit_timestamp);
      }

      // calculate the latency: time now for received event action minus time of insert in database
      latencyTrend.add(now - updated, {type: type});
      counterReceived.add(1);

      check(msg, {
        'got realtime notification': (msg) => msg.topic === 'realtime:*',
      });
    });

    socket.on('error', (e) => {
      if (e.error() != 'websocket: close sent') {
        console.error('An unexpected error occured: ', e.error());
      }
    });

    socket.setTimeout(function() {
      socket.close();
    }, duration * 1000);
  });

  check(res, {'status is 101': (r) => r && r.status === 101});
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
