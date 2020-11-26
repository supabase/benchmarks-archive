// This test reads from random rows in a table with 1 million rows

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const supabaseUrl = __ENV.SUPABASE_URL
const supabaseKey = __ENV.SUPABASE_KEY

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 10,
  discardResponseBodies: true,
  compatibilityMode: 'base',
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.05'],
    http_req_duration: ['p(99)<100'], // 99% of requests must complete below 100ms
  },
}

export function setup() {
  // see read-setup.js to setup 1 million rows for read test
}

export default function () {
  const params = {
    headers: {
      apiKey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      Range: '0-9',
    },
  }
  const res = http.get(
    `${supabaseUrl}/rest/v1/read?select=id&id=eq.${Math.floor(Math.random() * 1000000 + 1)}`,
    params
  )
  myFailRate.add(res.status !== 200)
  if (res.status !== 200) {
    console.log(res.status)
  }
}
