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
  // empty the current table
  const delParams = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
    },
  }
  http.del(`${supabaseUrl}/read`, {}, delParams)

  // add in 10 rows
  const insertParams = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  }
  const body = Array.from(Array(10)).map(() => ({}))
  http.post(`${supabaseUrl}/rest/v1/read`, JSON.stringify(body), insertParams)
}

export default function () {
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Range: '0-9',
    },
  }
  const res = http.get(`${supabaseUrl}/read?select=*`, params)
  myFailRate.add(res.status !== 200)
}
