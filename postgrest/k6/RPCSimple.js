import { Rate } from "k6/metrics";
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
  let num =  Math.floor((Math.random() * 347) + 1);
  let res = http.get(URL + `/rpc/add_them?a=${num}&b=${num+1}&c=${num+2}&d=${num+3}&e=${num+4}`);
  myFailRate.add(res.status !== 200);
}
