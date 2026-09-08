// Offline audit reproductions. No real credentials or network calls are used.
// Passing assertions confirm current weaknesses, not secure behavior.
import assert from 'node:assert/strict';
import payments from '../mobile-api/api/payments/index.js';
import cancel from '../mobile-api/api/gifts/[reference]/cancel/index.js';
import claim from '../mobile-api/api/gifts/[reference]/claim/confirm.js';
import lookup from '../mobile-api/api/gifts/[reference].js';

process.env.TWOSETTLE_API_KEY = 'audit-dummy-key';
process.env.TWOSETTLE_SECRET_KEY = 'audit-dummy-secret';
let calls = [];
globalThis.fetch = async (url, options) => {
  calls.push({ url, ...options });
  return { ok: true, status: 200, json: async () => ({
    data: { reference: '2S-ABC123', status: 'pending', payer: { phone: 'audit-private-value' } },
  }) };
};
async function invoke(handler, req) {
  const res = { setHeader() {}, status(code) { this.code = code; return this; }, json(body) { this.body = body; } };
  calls = [];
  await handler({ headers: {}, ...req }, res);
  return res;
}

let res = await invoke(cancel, { method: 'POST', query: { reference: 'ABC123' } });
assert.equal(res.code, 200);
assert.ok(calls[0].headers['x-signature']);
console.log('CONFIRMED: cancellation signs an anonymous request with no ownership proof');

res = await invoke(claim, { method: 'POST', query: { reference: 'ABC123' }, body: { receiver: { bankCode: '000013', accountNumber: '0123456789' } } });
assert.equal(res.code, 200);
assert.ok(calls[0].headers['x-signature']);
console.log('CONFIRMED: claim signs an anonymous request containing only reference and bank details');

res = await invoke(payments, { method: 'POST', body: { fiatAmount: 100, payer: { chatId: 'arbitrary-user', phone: 'arbitrary-phone' } } });
assert.equal(res.code, 200);
assert.equal(JSON.parse(calls[0].body).payer.chatId, 'arbitrary-user');
console.log('CONFIRMED: anonymous caller controls the upstream payer identity');

res = await invoke(payments, { method: 'POST', body: { fiatAmount: 100 } });
assert.equal(res.code, 200);
assert.ok(JSON.parse(calls[0].body).payer.phone);
console.log('CONFIRMED: missing payer receives a hard-coded identity');

res = await invoke(payments, { method: 'POST', body: { fiatAmount: 'Infinity' } });
assert.equal(res.code, 200);
assert.equal(JSON.parse(calls[0].body).fiatAmount, null);
console.log('CONFIRMED: non-finite amount passes validation and becomes null upstream');

res = await invoke(lookup, { method: 'GET', query: { reference: 'ABC123' } });
assert.equal(res.body.gift.payer.phone, 'audit-private-value');
console.log('CONFIRMED: anonymous lookup passes through nested upstream payer data');
