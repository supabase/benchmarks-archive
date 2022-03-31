import { check } from 'k6';
import ws from 'k6/ws';
import { Trend, Counter } from 'k6/metrics';

// eslint-disable-next-line max-len
const token = __ENV.MP_TOKEN || '';
const socketURI = __ENV.MP_URI || 'wss://project_slug.realtime.abc3.dev/socket/websocket';
const URL = `${socketURI}?apikey=${token}`;
const user = `NoKNwRWgDz${Math.random().toString(36).slice(2)}`;
const room = `zSbFOs3ccOh09yIf1-W${getRandomInt(0, 30)}`;

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
      // subscribe on presence and broadcast
      socket.send(JSON.stringify({
        topic: 'room:*',
        event: 'phx_join',
        payload: { user_token: token },
        ref: 0,
      }));
      // subscribe on POS broadcast events
      socket.send(JSON.stringify({
        topic: `room:public:messages:room_id=eq.${room}`,
        event: 'phx_join',
        payload: { user_token: token },
        ref: 1,
      }));
      // subscribe on realtime (Postgres DB updates)
      socket.send(JSON.stringify({
        topic: `realtime:public:messages:room_id=eq.${room}`,
        event: 'phx_join',
        payload: { user_token: token },
        ref: 2,
      }));
      // send access token to auth
      socket.send(JSON.stringify({
        topic: 'room:*',
        event: 'access_token',
        payload: { access_token: token },
        ref: 0,
      }));
      // send access token to auth
      socket.send(JSON.stringify({
        topic: `room:public:messages:room_id=eq.${room}`,
        event: 'access_token',
        payload: { access_token: token },
        ref: 1,
      }));
      // send access token to auth
      socket.send(JSON.stringify({
        topic: `realtime:public:messages:room_id=eq.${room}`,
        event: 'access_token',
        payload: { access_token: token },
        ref: 2,
      }))
      // Send heartbeat to server (timeout is probably around 1m)
      socket.setInterval(() => {
        socket.send(JSON.stringify({
          topic: 'phoenix',
          event: 'heartbeat',
          payload: {},
          ref: 0,
        }));
      }, 30 * 1000);
      let ctr = 5;
      // send fake mouse movement events ~100times/sec
      socket.setInterval(() => {
        socket.send(JSON.stringify({
          topic: `room:public:messages:room_id=eq.${room}`,
          event: 'broadcast',
          payload: {
            type: 'broadcast',
            event: 'POS',
            payload: {
              user_id: user,
              x: getRandomInt(0, 1200),
              y: getRandomInt(0, 600),
            }
          },
          ref: ctr++,
        }))
      }, 10);
    });

    socket.on('message', (msg) => {
      const now = new Date();
      // console.log('----------------');
      // console.log(msg);
      // console.log('----------------');
      msg = JSON.parse(msg);
      if (msg.event !== 'realtime') {
        return;
      }

      const type = msg.payload.payload.type;
      let updated = 0;
      if (msg.payload.payload.record) {
        updated = new Date(msg.payload.payload.record.created_at);
      } else {
        updated = new Date(msg.payload.commit_timestamp);
      }

      // calculate the latency for db update events: 
      // time now for received event action minus time of insert in database
      latencyTrend.add(now - updated, { type: type });
      counterReceived.add(1, { timeMark: Math.floor(now.getTime() / 1000) });

      check(msg, {
        'got realtime notification': (msg) => msg.topic === `room:public:messages:room_id=eq.${room}`,
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

function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  // The maximum is exclusive and the minimum is inclusive
  return Math.floor(Math.random() * (max - min) + min);
}