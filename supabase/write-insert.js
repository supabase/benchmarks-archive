// This test writes as many new rows as possible

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.SUPABASE_URL
const supabaseKey = __ENV.SUPABASE_KEY

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 500,
  discardResponseBodies: true,
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
      'Content-Type': 'application/json',
    },
  }
  http.del(`${supabaseUrl}/rest/v1/write`, {}, params)
}

export default function () {
  let n = Math.floor((Math.random() * 1000000000) + 1)
  const body = [{ id: n, slug: n }]
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  }
  const res = http.post(`${supabaseUrl}/rest/v1/write`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 201)
  if (res.status !== 201) {
    console.log(res.status)
  }
}
