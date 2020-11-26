// This test updates as many rows as possible to random rows

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.SUPABASE_URL
const supabaseKey = __ENV.SUPABASE_KEY

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
    // see README to setup 1 million rows for write-update test
  }

export default function () {
  const body = [{ slug: 5 }]
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
  }
  // we can use the 1 million row table 'read'
  const res = http.patch(`${supabaseUrl}/rest/v1/read?id=eq.${Math.floor(Math.random() * 1000000 + 1)}`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 201)
  if (res.status !== 201 && res.status !== 204) {
    console.log(res.status)
  }
}
