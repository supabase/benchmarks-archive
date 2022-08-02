import http from 'k6/http'
import { Rate } from 'k6/metrics'

import { randomString, uuidv4 } from 'https://jslib.k6.io/k6-utils/1.1.0/index.js'

const supabaseUrl = __ENV.SUPABASE_URL
const supabaseKey = __ENV.SUPABASE_KEY
const objectSize = __ENV.OBJECT_SIZE

let objectContent
switch (objectSize) {
  case "100kib":
  case "1mib":
  case "10mib":
    objectContent = open(`./assets/${objectSize}.bin`, 'b')
    break
  default:
    throw new Error(`Please specify an \`OBJECT_SIZE\` environment variable of "100kib", "1mib", or "10mib"`)
}

const myFailRate = new Rate('failed requests')

export let options = {
  vus: 10,
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
  return { bucketName }
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
  const objectName = uuidv4()
  const res = http.post(`${supabaseUrl}/object/${data.bucketName}/${objectName}`, objectContent, {
    headers: {
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/octet-stream',
    },
  })
  myFailRate.add(res.status !== 200)
  if (res.status !== 200) {
    console.log(res.status)
  }
}
