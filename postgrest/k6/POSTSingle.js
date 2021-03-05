import { Rate, Gauge } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const NGINX_PREFIX = __ENV.PGRBENCH_SETUP.startsWith("with-nginx")?"/api":"";

const URL = "http://" + __ENV.HOST + NGINX_PREFIX;

const RATE = (function(){
  if(__ENV.PGRBENCH_SETUP == "with-nginx")
    return 1200;
  else if(__ENV.PGRBENCH_SETUP == "with-nginx-best-config")
    return 1450;
  else if(__ENV.VERSION == 'v701'){
    switch(__ENV.HOST){
      case 'c5xlarge':  return 1500;
      case 't3axlarge': return 1300;
      case 't3alarge':  return 1300;
      case 't3amedium': return 1300;
      case 't3amicro':  return 1300;
      case 't3anano':   return 1300;
      default:          return 1000;
    }
  }
  else switch(__ENV.HOST){
      case 'c5xlarge':  return 1600;
      case 't3axlarge': return 1600;
      case 't3alarge':  return 1600;
      case 't3amedium': return 1600;
      case 't3amicro':  return 1600;
      case 't3anano':   return 1600;
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
  let body = JSON.stringify({
    employee_id: __ITER + 100
  , first_name:  'Virtual ' + __ITER
  , last_name:   'User '    + __ITER
  , title:       'Load Tester'
  , reports_to:  1
  , birth_date:  '1920-01-01'
  , hire_date:   '2020-01-01'
  , address:     '666 10 Street SW'
  , city:        'Calgary'
  , state:       'AB'
  , country:     'Canada'
  , postal_code: 'T2P 5G'
  , phone:       '(403) 246-9887'
  , fax:         '+1 (403) 246-9899'
  , email:       'vu' + __ITER + '@chinookcorp.com'
  });
  let res = http.post(URL + "/employee", body, {headers: { 'Content-Type': 'application/json' }});
  myFailRate.add(res.status !== 201);
}

export function teardown(data) {
  http.del(URL + "/employee?title=eq.Load%20Tester", {}, {headers: { 'Prefer': 'count=exact' }});
}
