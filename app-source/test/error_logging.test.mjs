import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';
import { fetchWithTimeout, json } from '../../mobile-api/lib/signing.js';
import { safeErrorText } from '../../mobile-api/lib/errorLogging.js';

const originalFetch = globalThis.fetch;
const originalError = console.error;
let logs;
beforeEach(() => { logs = []; console.error = value => logs.push(JSON.parse(value)); });
afterEach(() => { globalThis.fetch = originalFetch; console.error = originalError; });

test('logs upstream validation details without consuming or changing the response', async () => {
  const body = { error: 'Validation failed', code: 'VALIDATION_ERROR',
    details: { fieldErrors: { receiver: ['Rejected account 0123456789'] } } };
  globalThis.fetch = async () => new Response(JSON.stringify(body), { status: 400 });
  const response = await fetchWithTimeout('https://example.com/v1/payments?token=hidden', { method: 'POST' });
  assert.deepEqual(await response.json(), body);
  assert.equal(logs[0].status, 400);
  assert.equal(logs[0].route, '/v1/payments');
  assert.deepEqual(logs[0].fields, ['receiver']);
  assert.ok(!JSON.stringify(logs).includes('0123456789'));
  assert.ok(!JSON.stringify(logs).includes('hidden'));
});

test('logs transport errors and preserves the original exception', async () => {
  const error = new Error('Request failed account=0123456789 token=private');
  globalThis.fetch = async () => { throw error; };
  await assert.rejects(fetchWithTimeout('https://example.com/v1/payments'), value => value === error);
  assert.equal(logs[0].event, 'upstream_exception');
  assert.ok(!JSON.stringify(logs).includes('private'));
  assert.ok(!JSON.stringify(logs).includes('0123456789'));
});

test('logs local errors and logical failures without changing response data', () => {
  const res = { req: { method: 'POST', url: '/api/payments?secret=hidden' },
    setHeader() {}, status(status) { this.statusCode = status; return this; },
    json(body) { this.body = body; } };
  const body = { ok: false, error: 'Authentication required.' };
  json(res, 401, body);
  assert.equal(res.body, body);
  assert.equal(logs[0].route, '/api/payments');
  json(res, 200, body);
  assert.equal(logs.length, 2);
});

test('successful requests produce no error logs', async () => {
  globalThis.fetch = async () => new Response('{"ok":true}');
  await fetchWithTimeout('https://example.com/v1/payments');
  assert.equal(logs.length, 0);
});

test('redacts credentials, PINs, account numbers and emails', () => {
  const text = safeErrorText('pin=1234 Bearer abc.def.ghi account 0123456789 a@b.com');
  for (const secret of ['1234', 'abc.def.ghi', '0123456789', 'a@b.com']) {
    assert.ok(!text.includes(secret));
  }
});
