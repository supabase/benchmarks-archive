// Load test for the simple read schema with 1 mil rows
// Not related to the Chinook schema

import http from 'k6/http'
import { Rate } from 'k6/metrics'

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  switch(__ENV.HOST){
    case 't3axlarge': return 1300;
    case 't3alarge': return 950;
    case 't3asmall': return 750;
    case 't3amicro': return 350;
    case 't3anano':  return 150;
    default:         return 150;
  }
})();

const myFailRate = new Rate('failed requests')

export let options = {
  discardResponseBodies: true,
  scenarios: {
    constant_request_rate: {
      executor: 'constant-arrival-rate',
      rate: RATE,
      timeUnit: '1s',
      duration: '30s',
      preAllocatedVUs: 100,
      maxVUs: 600,
    }
  },
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
