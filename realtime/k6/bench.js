import ws from 'k6/ws';
import { check } from 'k6';

const URL = `ws://${__ENV.REALTIME_URL}:4000/socket/websocket`

export const options = {
  duration: '1m',
  vus: 1000
}

export default () => {
  const res = ws.connect(URL, {}, (socket) => {
    socket.on('open', () => {
      // Join channel
      socket.send(JSON.stringify({
        topic: 'realtime:*',
        event: 'phx_join',
        payload: {},
        ref: 0
      }))
      socket.setInterval(() => {
        // Send heartbeat to server (timeout is probably around 1m)
        socket.send(JSON.stringify({
          topic: 'phoenix',
          event: 'heartbeat',
          payload: {},
          ref: 0
        }))
      }, 30 * 1000)
    })

    socket.on('message', (msg) => {
      msg = JSON.parse(msg)
      if (msg.event === 'phx_reply') {
        return
      }

      check(msg, { 'got realtime notification': (msg) => msg.topic === 'realtime:*' })
    })

    socket.on('error', (e) => {
      if (e.error() != 'websocket: close sent') {
        console.error('An unexpected error occured: ', e.error())
      }
    })

    socket.setTimeout(function() {
      socket.close()
    }, 60 * 1000)
  })

  check(res, { 'status is 101': (r) => r && r.status === 101 })
}
