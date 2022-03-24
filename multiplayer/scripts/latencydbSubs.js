import { check } from 'k6';
import ws from 'k6/ws';
import { Trend, Counter } from 'k6/metrics';

// eslint-disable-next-line max-len
const token = __ENV.MP_TOKEN || '';
const socketURI = __ENV.MP_URI || 'ws://hcsnoerwwpaigmizfxmg.multiplayer.red/socket/websocket';
const URL = `${socketURI}?apikey=${token}`;

// reports
const latencyTrend = new Trend('latency_trend');
const counterReceived = new Counter('received_updates');

// Test params
// test duration
const baseDuration = __ENV.DURATION || 60;
// delay for connection time
const delay = __ENV.DELAY || 60;
const duration = parseInt(baseDuration) + parseInt(delay) + 15;

// thresholds is a workaround to get total number of received events per second
const to = {};
const started = Math.floor((new Date()).getTime() / 1000);
for (let i = 0; i < duration; i++) {
  to[`received_updates{timeMark:${started + i}}`] = ['count>=0'];
}

// test options
export const options = {
  duration: `${duration}s`,
  vus: 1,
  thresholds: to,
  summaryTrendStats: ['avg', 'med', 'p(99)', 'p(95)', 'p(0.1)', 'count'],
};

export default () => {
  // connect to realtime
  const res = ws.connect(URL, {}, (socket) => {
    socket.on('open', () => {
      // Join channel
      socket.send(JSON.stringify({
        topic: 'realtime:*',
        event: 'phx_join',
        payload: { user_token: token },
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
      latencyTrend.add(now - updated, { type: type });
      counterReceived.add(1, { timeMark: Math.floor(now.getTime() / 1000) });

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

  check(res, { 'status is 101': (r) => r && r.status === 101 });
};
