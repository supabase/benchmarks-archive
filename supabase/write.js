import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.supabaseUrl
const supabaseKey = __ENV.supabaseKey

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
  http.del(`${supabaseUrl}/write`, {}, params)
}

export default function () {
  const body = [{}]
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  }
  const res = http.post(`${supabaseUrl}/write`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 201)
}
