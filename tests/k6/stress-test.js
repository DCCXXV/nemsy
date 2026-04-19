/**
 * nemsy API stress test
 *
 *   1. JWT_SECRET=... go run ./cmd/gen-token <user_id>
 *   2. Get a subject ID and resource ID from the DB or the app UI
 *   3. k6 run \
 *        -e BASE_URL=https://api.nemsy.org \
 *        -e JWT_TOKEN=<token> \
 *        -e SUBJECT_ID=1 \
 *        -e RESOURCE_ID=1 \
 *        stress-test.js
 */

import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("error_rate");
const meLatency = new Trend("latency_me", true);
const subjectsLatency = new Trend("latency_subjects", true);
const resourcesLatency = new Trend("latency_resources", true);
const searchLatency = new Trend("latency_search", true);
const resourceDetailLatency = new Trend("latency_resource_detail", true);

export const options = {
    stages: [
        { duration: "30s", target: 10 }, //10 VUs
        { duration: "2m", target: 10 }, // wait
        { duration: "30s", target: 50 }, //50 VUs
        { duration: "2m", target: 50 }, // wait
        { duration: "30s", target: 100 }, // 100 VUs
        { duration: "2m", target: 100 }, // wait
        { duration: "30s", target: 0 }, // end
    ],
    thresholds: {
        http_req_duration: ["p(95)<500"], // 95% of requests under 500 ms
        error_rate: ["rate<0.01"], // error rate under 1%
    },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";
const JWT_TOKEN = __ENV.JWT_TOKEN;
const SUBJECT_ID = __ENV.SUBJECT_ID || "1";
const RESOURCE_ID = __ENV.RESOURCE_ID || "1";
const SEARCH_TERM = __ENV.SEARCH_TERM || "calculo";

if (!JWT_TOKEN) {
    throw new Error(
        "JWT_TOKEN env var is required. Run gen-token.go to generate one.",
    );
}

const headers = {
    "Content-Type": "application/json",
    Cookie: `session_token=${JWT_TOKEN}`,
};

function browseFlow() {
    let r = http.get(`${BASE_URL}/api/me`, { headers });
    meLatency.add(r.timings.duration);
    errorRate.add(r.status !== 200);
    check(r, { "me: 200": (res) => res.status === 200 });

    sleep(0.3);

    r = http.get(`${BASE_URL}/api/me/subjects`, { headers });
    subjectsLatency.add(r.timings.duration);
    errorRate.add(r.status !== 200);
    check(r, { "subjects: 200": (res) => res.status === 200 });

    sleep(0.3);

    r = http.get(`${BASE_URL}/api/subjects/${SUBJECT_ID}/resources`, {
        headers,
    });
    resourcesLatency.add(r.timings.duration);
    errorRate.add(r.status !== 200);
    check(r, { "subject resources: 200": (res) => res.status === 200 });
}

function searchFlow() {
    const r = http.get(`${BASE_URL}/api/resources/search?q=${SEARCH_TERM}`, {
        headers,
    });
    searchLatency.add(r.timings.duration);
    errorRate.add(r.status !== 200);
    check(r, { "search: 200": (res) => res.status === 200 });
}

function resourceDetailFlow() {
    const r = http.get(`${BASE_URL}/api/resources/${RESOURCE_ID}`, { headers });
    resourceDetailLatency.add(r.timings.duration);
    errorRate.add(r.status !== 200);
    check(r, { "resource detail: 200": (res) => res.status === 200 });
}

export default function () {
    const roll = Math.random();

    if (roll < 0.5) {
        browseFlow();
    } else if (roll < 0.8) {
        searchFlow();
    } else {
        resourceDetailFlow();
    }

    sleep(Math.random() * 1 + 0.5);
}
