import http from 'k6/http'
import { Rate } from 'k6/metrics'

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
  // we use the firestore SDK for this, see read-setup.js
}

export default function () {
  const res = http.post(
    `${__ENV.BASE_FIRESTORE_URL}:runQuery`,
    JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'read' }],
        select: {
          fields: [{ fieldPath: 'id' }],
        },
        where: {
          compositeFilter: {
            filters: [
              {
                fieldFilter: {
                  field: {
                    fieldPath: 'id',
                  },
                  op: 'EQUAL',
                  value: {
                    integerValue: Math.floor((Math.random() * 1000000) + 1),
                  },
                },
              },
            ],
            op: 'AND',
          },
        },
        limit: 1,
      },
    })
  )
  myFailRate.add(res.status !== 200)
}
