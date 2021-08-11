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
  },
}

export default function () {
  const res = http.get(`${supabaseUrl}/storage/v1/bucket`, {
    headers: {
      Authorization: `Bearer ${supabaseKey}`,
    },
  })
  myFailRate.add(res.status !== 200)
  if (res.status !== 200) {
    console.log(res.status)
  }
}
