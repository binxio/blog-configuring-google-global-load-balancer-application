import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics
export let errorCount = new Counter('errors');
export let errorRate = new Rate('error_rate');
export let responseTrend = new Trend('response_time_trend');

// Test configuration
export let options = {
    stages: [
        // Ramp-up to 500 users over 5 minutes
        { duration: '4m', target: 500 },
        // Stay at 500 users for 2 minutes
        { duration: '2m', target: 500 },
        // Ramp-down to 0 users over 2 minutes
        { duration: '2m', target: 0 },
    ],

    thresholds: {
        // HTTP request duration should be below 500ms for 95% of requests
        http_req_duration: ['p(95)<500'],
        // HTTP request failed rate should be below 1%
        http_req_failed: ['rate<0.01'],
        // Custom error rate should be below 1%
        error_rate: ['rate<0.01'],
    },
};

// const BASE_URL = 'http://localhost:1337';
const BASE_URL = 'http://paas-monitor.google.binx.dev';

export default function () {
    // Make HTTP GET request to /status endpoint
    let response = http.get(`${BASE_URL}/status`, {
        headers: {
            'Accept': 'application/json',
            'User-Agent': 'k6-load-test',
        },
        timeout: '30s',
    });

    // Check response status and content
    let checkRes = check(response, {
        'status is 200': (r) => r.status === 200,
        'response has body': (r) => r.body && r.body.length > 0,
        'content-type is correct': (r) => r.headers['Content-Type'] &&
            (r.headers['Content-Type'].includes('application/json')),
    });

    // Track custom metrics
    if (!checkRes) {
        errorCount.add(1);
        errorRate.add(true);
    } else {
        errorRate.add(false);
        responseTrend.add(response.timings.duration);
    }


    // Log errors for debugging
    if (response.status !== 200) {
        console.error(`Request failed: ${response.status} - ${response.status_text}`);
        console.error(`Response body: ${response.body}`);
    }

    // Wait 0.5 seconds between requests
    sleep(0.5);
}

// Setup function - runs once before the test starts
export function setup() {
    console.log(`Starting load test against: ${BASE_URL}/status`);

    // Test connectivity before starting the load test
    let response = http.get(`${BASE_URL}/status`, { timeout: '10s' });
    if (response.status !== 200) {
        console.error(`Setup check failed: ${response.status} - ${response.status_text}`);
        console.error('Make sure the service is accessible before running the load test');
    } else {
        console.log('Setup check passed - service is accessible');
    }

    return { baseUrl: BASE_URL };
}

// Teardown function - runs once after the test ends
export function teardown(data) {
    console.log(`Load test completed for: ${data.baseUrl}/status`);
}
