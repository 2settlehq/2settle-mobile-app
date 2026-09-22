import assert from 'node:assert/strict';
import { test, beforeEach, afterEach } from 'node:test';
import handler from '../../mobile-api/api/payments/index.js';

const oldFetch = globalThis.fetch;
const oldKey = process.env.TWOSETTLE_API_KEY;
const oldSecret = process.env.TWOSETTLE_SECRET_KEY;
let forwarded;
beforeEach(() => {
  process.env.TWOSETTLE_API_KEY = 'test-key';
  process.env.TWOSETTLE_SECRET_KEY = 'test-secret';
  forwarded = null;
  globalThis.fetch = async (url, options) => {
    if (url.endsWith('/users/me')) return new Response(JSON.stringify({ data: {
      user: { id: 'requester-id' }, identities: [
        { type: 'phone', identifier: '+2348012345678', verifiedAt: '2026-09-22' },
      ],
    } }));
    forwarded = JSON.parse(options.body);
    return new Response(JSON.stringify({ data: { reference: '2S-ABC123',
      type: forwarded.type, status: 'created', fiatAmount: 10000, fiatCurrency: 'NGN' } }));
  };
});
afterEach(() => {
  globalThis.fetch = oldFetch;
  if (oldKey === undefined) delete process.env.TWOSETTLE_API_KEY;
  else process.env.TWOSETTLE_API_KEY = oldKey;
  if (oldSecret === undefined) delete process.env.TWOSETTLE_SECRET_KEY;
  else process.env.TWOSETTLE_SECRET_KEY = oldSecret;
});
async function invoke(body) {
  const res = { setHeader() {}, status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; } };
  await handler({ method: 'POST', headers: { authorization: 'Bearer test-token' }, body }, res);
  return res;
}
test('request maps authenticated caller to receiver, leaving payer and crypto unset', async () => {
  const res = await invoke({ type: 'request', fiatAmount: 10000,
    receiver: { bankCode: '000013', accountNumber: '0123456789', phone: 'forged' },
    payer: { chatId: 'forged' }, metadata: { description: 'Invoice 1', autoSettle: true } });
  assert.equal(res.body.payment.reference, '2S-ABC123');
  assert.deepEqual(forwarded.receiver, { bankCode: '000013', accountNumber: '0123456789', phone: '+2348012345678' });
  for (const key of ['payer', 'crypto', 'network', 'chargeFrom']) assert.equal(Object.hasOwn(forwarded, key), false);
  assert.deepEqual(forwarded.metadata, { description: 'Invoice 1' });
});
test('request without receiver does not create backend payment', async () => {
  const res = await invoke({ type: 'request', fiatAmount: 10000 });
  assert.equal(res.statusCode, 400);
  assert.equal(forwarded, null);
});
test('gift and transfer retain verified payer identity', async () => {
  for (const type of ['gift', 'transfer']) {
    const res = await invoke({ type, fiatAmount: 10000, crypto: 'BTC', network: 'bitcoin',
      receiver: { bankCode: '000013', accountNumber: '0123456789' } });
    assert.equal(res.statusCode, 200);
    assert.deepEqual(forwarded.payer, { chatId: 'requester-id', phone: '+2348012345678' });
    assert.equal(forwarded.crypto, 'BTC');
    assert.equal(forwarded.network, 'bitcoin');
  }
});
