import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  vus: 3,
  duration: __ENV.DURATION || '1m',
  discardResponseBodies: true,
  thresholds: {
    http_req_duration: ['p(95)<500'],
    'http_req_duration{route:homepage}': ['p(95)<500'],
    'http_req_duration{route:health}': ['p(95)<200'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate==1'],
  },
};

export default function () {
  const health = http.get(`${BASE_URL}/health`, {
    tags: { route: 'health' },
    responseType: 'text',
  });

  check(health, {
    'health returns 200': (r) => r.status === 200,
    'health reports ok': (r) => {
      try {
        return r.json('status') === 'ok';
      } catch (_) {
        return false;
      }
    },
  });

  const homepage = http.get(`${BASE_URL}/`, {
    tags: { route: 'homepage' },
    responseType: 'text',
  });

  check(homepage, {
    'homepage returns 200': (r) => r.status === 200,
    'homepage contains ticket list': (r) =>
      typeof r.body === 'string' && r.body.includes('Latest tickets ('),
    'homepage shows 1 to 50 tickets': (r) => {
      if (typeof r.body !== 'string') return false;
      const rows = r.body.match(/<tr class="status-/g) || [];
      return rows.length >= 1 && rows.length <= 50;
    },
  });

  sleep(1);
}
