import { Rate } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://" + __ENV.HOST;

const RATE = (function(){
  if(__ENV.VERSION == 'v701'){
    switch(__ENV.HOST){
      case 'c5xlarge':  return 2400;
      case 't3axlarge': return 1600;
      case 't3anano':   return 1500;
      default:          return 1000;
    }
  }
  else switch(__ENV.HOST){
      case 'c5xlarge':  return 3000;
      case 't3axlarge': return 2300;
      case 't3anano':   return 2200;
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
  let id =  Math.floor((Math.random() * 275) + 1);
  let res = http.get(URL + "/rpc/ret_artists?select=*&artist_id=eq." + id);
  myFailRate.add(res.status !== 200);
}
