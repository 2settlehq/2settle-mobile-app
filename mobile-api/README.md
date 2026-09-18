# 2Settle Mobile API

Small Vercel proxy for the 2Settle mobile app.

## Environment Variables

Set these in Vercel, not in the repository:

- `TWOSETTLE_API_KEY`
- `TWOSETTLE_SECRET_KEY` - used only on the server to sign upstream requests

## Endpoints

`POST /api/banks/resolve`

Request:

```json
{
  "bankCode": "000013",
  "accountNumber": "0123456789"
}
```

`GET /api/gifts/:reference`

The reference can be sent as `2S-AND6DF` or `AND6DF`; the proxy normalizes it to
the full `2S-XXXXXX` format before signing the upstream `GET
/v1/payments/:reference` request.

Response:

```json
{
  "ok": true,
  "valid": true,
  "reference": "2S-AND6DF",
  "amount": "5000",
  "currency": "NGN",
  "status": "pending"
}
```

`POST /api/payments/estimate`

Sessionless — no bearer token required. Signs and forwards the upstream
`POST /v1/payments/estimate` request (payment-engine's real endpoint —
see `payment-engine/backend/src/routes/payment.routes.ts`). Locks a rate
and calculates fees without creating a session, wallet, or any DB record.

Request:

```json
{
  "fiatAmount": 5000,
  "fiatCurrency": "NGN",
  "crypto": "USDT",
  "network": "trc20",
  "chargeFrom": "crypto"
}
```

`fiatCurrency` defaults to `NGN` and `chargeFrom` defaults to `crypto` if omitted.

Response:

```json
{
  "ok": true,
  "estimate": {
    "cryptoAmount": 3.21,
    "crypto": "USDT",
    "network": "trc20",
    "fiatAmount": 5000,
    "fiatCurrency": "NGN",
    "rate": 1600,
    "conversionFee": 0,
    "processingFee": 500,
    "chargeFrom": "crypto",
    "expiresAt": "2026-09-17T06:30:00.000Z"
  }
}
```

`POST /api/gifts/:reference/claim/confirm`

Request:

```json
{
  "receiver": {
    "bankCode": "000013",
    "accountNumber": "0123456789"
  }
}
```

`POST /api/gifts/:reference/cancel`

Cancels a pending gift/payment by signing the upstream
`/v1/payment/:reference/cancel` request server-side.

Response:

```json
{
  "ok": true,
  "reference": "2S-AND6DF",
  "status": "cancelled"
}
```

Response:

```json
{
  "ok": true,
  "valid": true,
  "accountName": "ACCOUNT NAME",
  "bankName": "BANK NAME",
  "bankCode": "000013",
  "accountNumber": "0123456789"
}
```
