import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.supabaseUrl
const supabaseKey = __ENV.supabaseKey

function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = (Math.random() * 16) | 0,
      v = c == 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.05'],
    http_req_duration: ['p(99)<100'], // 99% of requests must complete below 100ms
  },
}

export function setup() {
  // make sure we are starting off with a clean table
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
    },
  }
  http.del(`${supabaseUrl}/rest/v1/write`, {}, params)
}

export default function () {
  const body = [
    {
      id: uuidv4(),
      slug: uuidv4(),
    },
  ]
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  }
  const res = http.post(`${supabaseUrl}/rest/v1/write`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 201)
}
