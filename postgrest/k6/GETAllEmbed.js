import { Rate } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  if(__ENV.VERSION == 'v701'){
    switch(__ENV.HOST){
      case 'c5xlarge':  return 70;
      case 't3axlarge': return 55;
      case 't3alarge':  return 40;
      case 't3amedium': return 40;
      case 't3amicro':  return 40;
      case 't3anano':   return 40;
      default:          return 40;
    }
  }
  else switch(__ENV.HOST){
      case 'c5xlarge':  return 70;
      case 't3axlarge': return 65;
      case 't3alarge':  return 40;
      case 't3amedium': return 40;
      case 't3amicro':  return 40;
      case 't3anano':   return 40;
      default:          return 40;
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
  let res = http.get(URL + "/album?select=*,track(*,genre(*))");
  myFailRate.add(res.status !== 200);
}
