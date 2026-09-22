import assert from 'node:assert/strict';
import { afterEach, beforeEach, test } from 'node:test';
import handler from '../../mobile-api/api/payments/estimate.js';

const originalFetch = globalThis.fetch;
const originalKey = process.env.TWOSETTLE_API_KEY;
const originalSecret = process.env.TWOSETTLE_SECRET_KEY;
let forwarded;

beforeEach(() => {
  process.env.TWOSETTLE_API_KEY = 'test-only-key';
  process.env.TWOSETTLE_SECRET_KEY = 'test-only-secret';
  forwarded = null;
  globalThis.fetch = async (_url, options) => {
    forwarded = JSON.parse(options.body);
    return new Response(JSON.stringify({ success: true, estimate: {
      cryptoAmount: 0.01, fiatAmount: 1000000, fiatCurrency: 'NGN',
      conversionFee: 10000, processingFee: 1000,
    } }), { status: 200 });
  };
});

afterEach(() => {
  globalThis.fetch = originalFetch;
  if (originalKey === undefined) delete process.env.TWOSETTLE_API_KEY;
  else process.env.TWOSETTLE_API_KEY = originalKey;
  if (originalSecret === undefined) delete process.env.TWOSETTLE_SECRET_KEY;
  else process.env.TWOSETTLE_SECRET_KEY = originalSecret;
});

async function invoke(body) {
  const res = {
    setHeader() {},
    status(value) { this.statusCode = value; return this; },
    json(value) { this.body = value; return this; },
  };
  await handler({ method: 'POST', body }, res);
  return res;
}

for (const [crypto, network] of [
  ['BTC', 'bitcoin'], ['BNB', 'bsc'], ['USDT', 'trc20'], ['TRX', 'tron'],
]) {
  test(`forwards ${crypto} input without adding fiatAmount`, async () => {
    const res = await invoke({ cryptoAmount: 0.01732628, crypto, network });
    assert.equal(res.statusCode, 200);
    assert.equal(forwarded.cryptoAmount, 0.01732628);
    assert.equal(Object.hasOwn(forwarded, 'fiatAmount'), false);
    assert.equal(forwarded.crypto, crypto);
    assert.equal(res.body.estimate.fiatAmount, '1000000');
    assert.equal(res.body.estimate.conversionFee, '10000');
    assert.equal(res.body.estimate.processingFee, '1000');
  });
}

test('naira input stays fiat-first even with BTC selected for payment', async () => {
  await invoke({ fiatAmount: 50000, crypto: 'BTC', network: 'bitcoin' });
  assert.equal(forwarded.fiatAmount, 50000);
  assert.equal(Object.hasOwn(forwarded, 'cryptoAmount'), false);
});

for (const error of [
  'Amount exceeds maximum limit. Maximum is 0.01732628 BTC.',
  'Amount exceeds maximum limit. Maximum is 2.5 BNB.',
  'Amount exceeds maximum limit. Maximum is ₦2,000,000.',
]) {
  test(`preserves the exact backend limit message: ${error}`, async () => {
    globalThis.fetch = async () => new Response(JSON.stringify({
      success: false, error,
    }), { status: 400 });
    const res = await invoke({ cryptoAmount: 1, crypto: 'BTC', network: 'bitcoin' });
    assert.equal(res.statusCode, 400);
    assert.equal(res.body.error, error);
    assert.equal(res.body.ok, false);
  });
}

for (const body of [{}, { cryptoAmount: 0 }, { cryptoAmount: -1 },
  { cryptoAmount: 'Infinity' }, { fiatAmount: 'invalid' }]) {
  test(`rejects invalid amounts before calling upstream: ${JSON.stringify(body)}`, async () => {
    const res = await invoke({ ...body, crypto: 'BTC', network: 'bitcoin' });
    assert.equal(res.statusCode, 400);
    assert.equal(forwarded, null);
  });
}
