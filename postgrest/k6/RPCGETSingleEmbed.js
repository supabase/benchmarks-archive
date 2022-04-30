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
  let id =  Math.floor((Math.random() * 347) + 1);
  let res = http.get(URL + "/rpc/ret_albums?select=album_id,title,artist_id,track(*,genre(*))&artist_id=eq." + id);
  myFailRate.add(res.status !== 200);
}
