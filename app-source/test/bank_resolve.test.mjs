import assert from 'node:assert/strict';
import { test, beforeEach, afterEach } from 'node:test';
import handler from '../../mobile-api/api/banks/resolve.js';

const originalFetch = globalThis.fetch;
const originalEnv = { ...process.env };
let calls;
beforeEach(() => {
  process.env.TWOSETTLE_API_KEY = 'test-key';
  process.env.TWOSETTLE_SECRET_KEY = 'test-secret';
  calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return new Response(JSON.stringify({ data: { accountName: 'Test Account', bankName: 'Test Bank' } }));
  };
});
afterEach(() => {
  globalThis.fetch = originalFetch;
  for (const key of ['TWOSETTLE_API_KEY', 'TWOSETTLE_SECRET_KEY']) {
    if (originalEnv[key] === undefined) delete process.env[key];
    else process.env[key] = originalEnv[key];
  }
});
async function invoke(body) {
  const res = { setHeader() {}, status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; } };
  await handler({ method: 'POST', headers: {}, body }, res);
  return res;
}
test('anonymous bank lookup is signed server-side and does not require /me', async () => {
  const res = await invoke({ bankCode: '000013', accountNumber: '0123456789' });
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.accountName, 'Test Account');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, 'https://api.2settle.io/v1/banks/resolve');
  assert.ok(calls[0].options.headers['x-signature']);
  assert.equal(calls[0].options.headers['x-api-key'], 'test-key');
  assert.equal(calls[0].options.headers.authorization, undefined);
});
test('invalid account is rejected before upstream lookup', async () => {
  const res = await invoke({ bankCode: '000013', accountNumber: '123' });
  assert.equal(res.statusCode, 400);
  assert.equal(calls.length, 0);
});
test('upstream validation error stays an error', async () => {
  globalThis.fetch = async () => new Response('{"error":"Account not found"}', { status: 404 });
  const res = await invoke({ bankCode: '000013', accountNumber: '0123456789' });
  assert.equal(res.statusCode, 404);
  assert.equal(res.body.ok, false);
});
