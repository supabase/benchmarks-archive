// Load test for the simple read schema with 1 mil rows
// Not related to the Chinook schema

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const URL = "http://pgrst";

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.1'],
    'http_req_duration': ['p(95)<1000']
  }
};

export default function () {
  const body = { slug: 10 }
  const params = {
    headers: {
      'Content-Type': 'application/json',
    }
  }
  const res = http.patch(`${URL}/read?id=eq.${Math.floor(Math.random() * 1000000 + 1)}`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 204)
}
