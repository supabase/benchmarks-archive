import { Rate, Gauge } from "k6/metrics";
import { check, group, sleep } from 'k6';
import http from 'k6/http';

const URL = "http://pgrst";

export const options = {
  duration: '30s',
  thresholds: {
    'failed requests': ['rate<0.1'],
    'http_req_duration': ['p(95)<1000']
  }
};

const myFailRate = new Rate('failed requests');

export default function() {
  let body = JSON.stringify(Array(20).fill({
    employee_id: __ITER + 100
  , first_name:  'Virtual ' + __ITER
  , last_name:   'User ' + __ITER
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
  }));
  let res = http.post(URL + "/employee?columns=employee_id,first_name,last_name,title,reports_to,birth_date,hire_date,address,city,state,country,postal_code,phone,fax,email", body, {headers: { 'Content-Type': 'application/json' }});
  myFailRate.add(res.status !== 201);
}

export function teardown(data) {
  http.del(URL + "/employee?title=eq.Load%20Tester", {}, {headers: { 'Prefer': 'count=exact' }});
}
