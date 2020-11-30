// This test reads from a single row as many times as possible

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.SUPABASE_URL
const supabaseKey = __ENV.SUPABASE_KEY

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 500,
  discardResponseBodies: true,
  compatibilityMode: 'base',
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.05'],
    http_req_duration: ['p(99)<100'], // 99% of requests must complete below 100ms
  },
}

export function setup() {
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Range: '0-9',
    },
  }
  http.post(`${supabaseUrl}/rest/v1/readsingle`, JSON.stringify({ id: 1, slug: 1 }), params)
}

export default function () {
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Range: '0-9',
    },
  }
  const res = http.get(`${supabaseUrl}/rest/v1/readsingle?select=id&id=eq.1`, params)
  myFailRate.add(res.status !== 200)
  if (res.status !== 200) {
    console.log(res.status)
  }
}
