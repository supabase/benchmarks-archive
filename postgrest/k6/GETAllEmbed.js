import { Rate } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://" + __ENV.HOST;

const RATE = (__ENV.HOST == 't2nano')? 40: 40;

export let options = {
  discardResponseBodies: true,
  scenarios: {
    constant_request_rate: {
      executor: 'constant-arrival-rate',
      rate: RATE,
      timeUnit: '1s',
      duration: '1m',
      preAllocatedVUs: 100,
      maxVUs: 600,
    }
  },
  thresholds: {
    'failed requests': ['rate<0.1'],
    'http_req_duration': ['p(95)<1000']
  }
};

const myFailRate = new Rate('failed requests');

export default function() {
  let res = http.get(URL + "/album?select=*,track(*,genre(*))");
  myFailRate.add(res.status !== 200);
}
