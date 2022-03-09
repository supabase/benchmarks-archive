import {check} from 'k6';
import ws from 'k6/ws';
import http from 'k6/http';
import {Rate, Trend, Counter} from 'k6/metrics';

const pgrstURL = __ENV.PG_REST_URL || 'https://hcsnoerwwpaigmizfxmg.supabase.net/rest/v1/egor';
// eslint-disable-next-line max-len
const pgrstToken = __ENV.PG_REST_TOKEN;

// eslint-disable-next-line max-len
const token = __ENV.MP_TOKEN;
const socketURI = __ENV.MP_URI || 'ws://hcsnoerwwpaigmizfxmg.multiplayer.red/socket/websocket';
const URL = `${socketURI}?apikey=${token}`;

const rate = __ENV.RATE || 2;

const myFailRate = new Rate('failed_requests');
const latencyTrend = new Trend('latency_trend');
const reqDBTrend = new Trend('request_db_trend');
const counterSent = new Counter('requests');
const counterReceived = new Counter('received_updates');

export const options = {
  duration: '1m',
  vus: 1,
};

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
        // currently not helping and connections terminated after 1 min anyway. Need to fix in MP.
        socket.send(JSON.stringify({
          topic: 'phoenix',
          event: 'heartbeat',
          payload: {},
          ref: 0,
        }));
      }, 30 * 1000);
      // sending inserts to postgrest as soon as we connect to MP.
      // We have to do it this way, because connections to multiplayer can live only for 1 minute now.
      socket.setInterval(() => {
        if (getRandomInt(0, options.vus) !== 0) {
          return;
        }
        const sendTime = new Date();
        const insert = http.post(
            pgrstURL,
            JSON.stringify({}), {
              headers: {
                'Content-Type': 'application/json',
                'apikey': pgrstToken,
                'Authorization': `Bearer ${pgrstToken}`,
                'Prefer': 'return=representation',
              },
            });
        myFailRate.add(insert.status !== 201);
        if (insert.status === 201) {
          counterSent.add(1);
          reqDBTrend.add(new Date(
              JSON.parse(insert.body)[0].created_at,
          ).getTime() - sendTime.getTime());
        }
      }, Math.ceil(1000 / rate));
    });

    socket.on('message', (msg) => {
      const now = new Date();
      // console.log(msg);
      msg = JSON.parse(msg);
      if (msg.event === 'phx_reply') {
        return;
      }

      const type = msg.payload.type;
      let updated = 0;
      if (msg.payload.record) {
        updated = new Date(msg.payload.record.created_at);
      } else {
        // this is for delete, but data will be dirty, because commit_timestamp has no millis.
        updated = new Date(msg.payload.commit_timestamp);
      }

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
    }, 60 * 1000);
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
