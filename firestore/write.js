import http from 'k6/http'
import { Rate } from 'k6/metrics'

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 10,
  discardResponseBodies: true,
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.05'],
    http_req_duration: ['p(99)<100'], // 99% of requests must complete below 100ms
  },
}

export function setup() {
}

export default function () {
  var n = Math.floor((Math.random() * 1000000000) + 1)
  const res = http.post(
    `${__ENV.BASE_FIRESTORE_URL}/read?documentId=${n}`,
    JSON.stringify({
      fields: {
        slug: {
          integerValue: n,
        },
      },
    })
  )
  myFailRate.add(res.status !== 200)
}
