import { Rate } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  if(__ENV.VERSION == 'v701'){
    switch(__ENV.HOST){
      case 'c5xlarge':  return 2400;
      case 't3axlarge': return 1600;
      case 't3anano':   return 1600;
      default:          return 1500;
    }
  }
  else switch(__ENV.HOST){
      case 'c5xlarge':  return 3000;
      case 't3axlarge': return 2200;
      case 't3anano':   return 2100;
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

const myFailRate = new Rate('failed requests');

export default function() {
  let res = http.get(URL + "/rpc/add_them?a=1&b=2&c=3&d=4&e=5");
  myFailRate.add(res.status !== 200);
}
