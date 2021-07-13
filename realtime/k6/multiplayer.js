import ws from 'k6/ws'
import http from 'k6/http'
import { check } from 'k6'

export const options = {
  scenarios: {
    websockets: {
      executor: 'constant-vus',
      exec: 'websockets',
      duration: '30s',
      vus: 1000
    },
    post_json: {
      executor: 'constant-vus',
      exec: 'post_json',
      startTime: '10s',
      duration: '20s',
      vus: 200
    },
  }
}

export const websockets = () => {
  const url = `${__ENV.WS_URL}/socket/websocket`
  const res = ws.connect(url, {}, (socket) => {
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
      check(msg, {
        'got realtime notification': (msg) => {
          // console.log(JSON.stringify(msg))
          return msg.topic === 'realtime:*'
        }
      })
    })

    socket.on('error', (e) => {
      if (e.error() != 'websocket: close sent') {
        console.error('An unexpected error occured: ', e.error())
      }
    })

    socket.setTimeout(function () {
      socket.close()
    }, 30 * 1000)
  })

  check(res, { 'status is 101': (r) => r && r.status === 101 })
}

export const post_json = () => {
  const url = `${__ENV.POST_URL}/api/broadcast`
  const payload = JSON.stringify({
    "changes": [
      {
        "columns": [
          { "flags": ["key"], "name": "id", "type": "int8", "type_modifier": 4294967295 },
          { "flags": [], "name": "value", "type": "text", "type_modifier": 4294967295 },
          { "flags": [], "name": "value2", "type": "varchar", "type_modifier": 4294967295 }
        ],
        "commit_timestamp": "2021-06-25T16:50:09Z",
        "record": { "id": __ITER, "value": "1", "value2": null },
        "schema": "public",
        "table": "stress", "type": "INSERT"
      }
    ],
    "commit_timestamp": "2021-06-25T16:50:09Z"
  })

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  }

  const res = http.post(url, payload, params)

  check(res, {
    'is status 200': (r) => r.status === 200,
  })

}
