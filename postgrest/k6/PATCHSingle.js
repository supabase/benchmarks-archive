import http from 'k6/http'
import { Rate } from 'k6/metrics'

const URL = "http://pgrst";

export const options = {
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.1'],
    'http_req_duration': ['p(95)<1000']
  }
};

const myFailRate = new Rate('failed requests')

export default function () {
  const body = { last_update: 'now' }
  const params = {
    headers: {
      'Content-Type': 'application/json',
    }
  }
  const res = http.patch(`${URL}/actor?actor_id=eq.${Math.floor(Math.random() * 203 + 1)}`, JSON.stringify(body), params)
  myFailRate.add(res.status !== 204)
}
