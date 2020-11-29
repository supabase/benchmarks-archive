import { Rate } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  if(__ENV.VERSION == 'v701'){
    switch(__ENV.HOST){
      case 'c5xlarge':  return 1050;
      case 't3axlarge': return 800;
      case 't3alarge':  return 500;
      case 't3amedium': return 500;
      case 't3amicro':  return 500;
      case 't3anano':   return 500;
      default:          return 500;
    }
  }
  else switch(__ENV.HOST){
      case 'c5xlarge':  return 1550;
      case 't3axlarge': return 1200;
      case 't3alarge':  return 810;
      case 't3amedium': return 810;
      case 't3amicro':  return 810;
      case 't3anano':   return 810;
      default:          return 500;
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
  let id =  Math.floor((Math.random() * 347) + 1);
  let res = http.get(URL + "/album?select=*,track(*,genre(*))&artist_id=eq." + id);
  myFailRate.add(res.status !== 200);
}
