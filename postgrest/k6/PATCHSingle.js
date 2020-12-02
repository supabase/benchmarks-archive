import http from 'k6/http'
import { Rate } from 'k6/metrics'

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  switch(__ENV.HOST){
    case 'c5xlarge':  return 1650;
    case 't3axlarge': return 1500;
    case 't3anano':   return 1500;
    default:          return 1000;
  }
})();

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
