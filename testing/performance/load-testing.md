# Performance & Load Testing Guide

## Overview

Performance testing ensures your application can handle expected (and unexpected) loads while maintaining acceptable response times.

## Load Testing with k6

### Installation
```bash
# macOS
brew install k6

# Linux
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Docker
docker run -i grafana/k6 run - <script.js
```

### Basic Load Test
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Ramp up to 20 users
    { duration: '1m', target: 20 },    // Stay at 20 users
    { duration: '30s', target: 50 },   // Ramp up to 50 users
    { duration: '2m', target: 50 },    // Stay at 50 users
    { duration: '30s', target: 0 },    // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.1'],    // Error rate under 10%
  },
};

export default function () {
  const res = http.get('https://api.example.com/products');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has products': (r) => JSON.parse(r.body).products.length > 0,
  });
  
  sleep(1);
}
```

### Authenticated Requests
```javascript
import http from 'k6/http';
import { check } from 'k6';

export function setup() {
  // Login once and share token
  const loginRes = http.post('https://api.example.com/auth/login', {
    email: 'test@example.com',
    password: 'password123',
  });
  
  const authToken = loginRes.json('token');
  return { authToken };
}

export default function (data) {
  const params = {
    headers: {
      'Authorization': `Bearer ${data.authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const res = http.get('https://api.example.com/user/profile', params);
  
  check(res, {
    'authenticated request successful': (r) => r.status === 200,
  });
}
```

### Complex Scenarios
```javascript
import http from 'k6/http';
import { group, check } from 'k6';

export const options = {
  scenarios: {
    browse_products: {
      executor: 'constant-vus',
      vus: 20,
      duration: '3m',
      exec: 'browseProducts',
    },
    checkout_flow: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 10 },
        { duration: '3m', target: 10 },
        { duration: '1m', target: 0 },
      ],
      exec: 'checkoutFlow',
    },
  },
};

export function browseProducts() {
  group('Browse Products', () => {
    const res = http.get('https://api.example.com/products');
    check(res, { 'products loaded': (r) => r.status === 200 });
    
    // View product detail
    const products = res.json('products');
    if (products.length > 0) {
      const productId = products[Math.floor(Math.random() * products.length)].id;
      const detailRes = http.get(`https://api.example.com/products/${productId}`);
      check(detailRes, { 'product detail loaded': (r) => r.status === 200 });
    }
  });
}

export function checkoutFlow() {
  group('Checkout Flow', () => {
    // Add to cart
    const cartRes = http.post('https://api.example.com/cart', {
      productId: 1,
      quantity: 2,
    });
    check(cartRes, { 'added to cart': (r) => r.status === 201 });
    
    // Checkout
    const checkoutRes = http.post('https://api.example.com/checkout', {
      paymentMethod: 'card',
    });
    check(checkoutRes, { 'checkout successful': (r) => r.status === 200 });
  });
}
```

## Database Performance Testing

### Query Performance
```javascript
// test-db-performance.js
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testQueryPerformance() {
  const queries = [
    {
      name: 'Simple select',
      sql: 'SELECT * FROM users WHERE id = $1',
      params: [1],
    },
    {
      name: 'Complex join',
      sql: `
        SELECT u.*, COUNT(o.id) as order_count
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.created_at > $1
        GROUP BY u.id
        LIMIT 100
      `,
      params: [new Date('2024-01-01')],
    },
  ];
  
  for (const query of queries) {
    const times = [];
    
    // Run multiple times for average
    for (let i = 0; i < 100; i++) {
      const start = process.hrtime.bigint();
      await pool.query(query.sql, query.params);
      const end = process.hrtime.bigint();
      times.push(Number(end - start) / 1000000); // Convert to ms
    }
    
    const avg = times.reduce((a, b) => a + b) / times.length;
    const max = Math.max(...times);
    const min = Math.min(...times);
    
    console.log(`${query.name}:`);
    console.log(`  Average: ${avg.toFixed(2)}ms`);
    console.log(`  Min: ${min.toFixed(2)}ms`);
    console.log(`  Max: ${max.toFixed(2)}ms`);
  }
}
```

### Connection Pool Testing
```javascript
async function testConnectionPool() {
  const concurrentQueries = 50;
  const iterations = 10;
  
  console.log(`Testing with ${concurrentQueries} concurrent queries...`);
  
  for (let i = 0; i < iterations; i++) {
    const start = Date.now();
    
    const promises = Array(concurrentQueries).fill(null).map(() =>
      pool.query('SELECT pg_sleep(0.1)')
    );
    
    await Promise.all(promises);
    
    const duration = Date.now() - start;
    console.log(`Iteration ${i + 1}: ${duration}ms`);
  }
}
```

## API Performance Testing with Artillery

### Installation
```bash
npm install -g artillery
```

### Basic Configuration
```yaml
# artillery-config.yml
config:
  target: "https://api.example.com"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 300
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Spike test"
  processor: "./processor.js"

scenarios:
  - name: "Browse and Purchase"
    flow:
      - get:
          url: "/products"
          capture:
            - json: "$.products[0].id"
              as: "productId"
      - think: 2
      - get:
          url: "/products/{{ productId }}"
      - think: 3
      - post:
          url: "/cart"
          json:
            productId: "{{ productId }}"
            quantity: 1
      - think: 2
      - post:
          url: "/checkout"
          json:
            paymentMethod: "card"
```

### Custom Functions
```javascript
// processor.js
module.exports = {
  beforeRequest: (requestParams, context, ee, next) => {
    // Add auth header
    requestParams.headers = requestParams.headers || {};
    requestParams.headers['Authorization'] = `Bearer ${context.vars.authToken}`;
    return next();
  },
  
  afterResponse: (requestParams, response, context, ee, next) => {
    // Custom metrics
    if (response.statusCode !== 200) {
      ee.emit('counter', 'http.response.error', 1);
    }
    return next();
  },
};
```

## Frontend Performance Testing

### Lighthouse CI
```javascript
// lighthouse-config.js
module.exports = {
  ci: {
    collect: {
      url: [
        'http://localhost:3000/',
        'http://localhost:3000/products',
        'http://localhost:3000/checkout',
      ],
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.95 }],
        'categories:seo': ['error', { minScore: 0.9 }],
        'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 3000 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

### Web Vitals Monitoring
```javascript
// monitor-performance.js
import { getCLS, getFID, getLCP, getTTFB, getFCP } from 'web-vitals';

function sendToAnalytics(metric) {
  // Send to your analytics endpoint
  fetch('/api/analytics', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
      id: metric.id,
      navigationType: metric.navigationType,
    }),
  });
}

// Monitor Core Web Vitals
getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getLCP(sendToAnalytics);
getTTFB(sendToAnalytics);
getFCP(sendToAnalytics);
```

## Memory & Resource Testing

### Node.js Memory Profiling
```javascript
// memory-test.js
const v8 = require('v8');
const fs = require('fs');

function captureHeapSnapshot(filename) {
  const heapSnapshot = v8.writeHeapSnapshot();
  fs.renameSync(heapSnapshot, filename);
  console.log(`Heap snapshot saved to ${filename}`);
}

async function runMemoryTest() {
  const iterations = 1000;
  const data = [];
  
  console.log('Initial memory:', process.memoryUsage());
  captureHeapSnapshot('heap-start.heapsnapshot');
  
  for (let i = 0; i < iterations; i++) {
    // Simulate memory-intensive operation
    data.push(new Array(1000).fill(Math.random()));
    
    if (i % 100 === 0) {
      const usage = process.memoryUsage();
      console.log(`Iteration ${i}:`, {
        rss: `${(usage.rss / 1024 / 1024).toFixed(2)} MB`,
        heapUsed: `${(usage.heapUsed / 1024 / 1024).toFixed(2)} MB`,
      });
    }
  }
  
  captureHeapSnapshot('heap-end.heapsnapshot');
  
  // Force garbage collection if available
  if (global.gc) {
    global.gc();
    console.log('After GC:', process.memoryUsage());
  }
}

// Run with: node --expose-gc memory-test.js
```

## Stress Testing Best Practices

### Gradual Load Increase
```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Baseline
    { duration: '5m', target: 100 },   // Sustain
    { duration: '2m', target: 200 },   // Double
    { duration: '5m', target: 200 },   // Sustain
    { duration: '2m', target: 400 },   // Double again
    { duration: '5m', target: 400 },   // Sustain
    { duration: '2m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // Track when performance degrades
    http_req_failed: ['rate<0.05'],
  },
};
```

### Monitoring During Tests
```bash
# Run k6 with real-time output
k6 run --out influxdb=http://localhost:8086/k6 script.js

# Monitor system resources
htop
iostat -x 1
netstat -i 1

# Database monitoring
SELECT query, calls, mean_exec_time, max_exec_time 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
```

## Reporting & Analysis

### Generate HTML Reports
```bash
# k6 HTML report
k6 run --out json=results.json script.js
k6-to-html results.json report.html

# Artillery report
artillery run config.yml --output results.json
artillery report results.json
```

### Custom Metrics Dashboard
```javascript
// metrics-server.js
const express = require('express');
const app = express();

const metrics = {
  requests: 0,
  errors: 0,
  responseTime: [],
};

app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    metrics.requests++;
    metrics.responseTime.push(duration);
    
    if (res.statusCode >= 400) {
      metrics.errors++;
    }
  });
  
  next();
});

app.get('/metrics', (req, res) => {
  const avgResponseTime = metrics.responseTime.reduce((a, b) => a + b, 0) / metrics.responseTime.length;
  
  res.json({
    requests: metrics.requests,
    errors: metrics.errors,
    errorRate: (metrics.errors / metrics.requests * 100).toFixed(2) + '%',
    avgResponseTime: avgResponseTime.toFixed(2) + 'ms',
    p95ResponseTime: percentile(metrics.responseTime, 0.95) + 'ms',
  });
});

function percentile(arr, p) {
  const sorted = arr.sort((a, b) => a - b);
  const index = Math.ceil(sorted.length * p) - 1;
  return sorted[index];
}
```