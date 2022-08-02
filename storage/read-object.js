import http from 'k6/http'
import { Rate } from 'k6/metrics'

import { randomString, uuidv4 } from 'https://jslib.k6.io/k6-utils/1.1.0/index.js'

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

export function setup() {
  const bucketName = uuidv4()
  http.post(
    `${supabaseUrl}/bucket`,
    JSON.stringify({ id: bucketName, name: bucketName, public: false }),
    {
      headers: {
        Authorization: `Bearer ${supabaseKey}`,
        'Content-Type': 'application/json',
      },
    }
  )
  const objectName = uuidv4()
  http.post(`${supabaseUrl}/object/${bucketName}/${objectName}`, randomString(1e5), {
    headers: {
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'text/plain',
    },
  })
  return { bucketName, objectName }
}

export function teardown(data) {
  const params = {
    headers: {
      Authorization: `Bearer ${supabaseKey}`,
    },
  }
  http.post(`${supabaseUrl}/bucket/${data.bucketName}/empty`, null, params)
  http.del(`${supabaseUrl}/bucket/${data.bucketName}`, null, params)
}

export default function (data) {
  const res = http.get(
    `${supabaseUrl}/object/authenticated/${data.bucketName}/${data.objectName}`,
    {
      headers: {
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  )
  myFailRate.add(res.status !== 200)
  if (res.status !== 200) {
    console.log(res.status)
  }
}
