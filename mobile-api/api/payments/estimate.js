import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  fetchWithTimeout,
} from "../../lib/signing.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/payments/estimate";
const DEFAULT_UPSTREAM_PATH = "/v1/payments/estimate";

const CRYPTO_CURRENCIES = new Set(["BTC", "ETH", "BNB", "TRX", "USDT", "USDC"]);
const NETWORKS = new Set([
  "bitcoin",
  "ethereum",
  "bsc",
  "tron",
  "polygon",
  "base",
  "erc20",
  "bep20",
  "trc20",
]);

function normalizePayload(body) {
  return {
    ...(body?.fiatAmount !== undefined ? { fiatAmount: Number(body.fiatAmount) } : {}),
    ...(body?.cryptoAmount !== undefined ? { cryptoAmount: Number(body.cryptoAmount) } : {}),
    fiatCurrency: String(body?.fiatCurrency || "NGN").trim().toUpperCase(),
    crypto: String(body?.crypto || "").trim().toUpperCase(),
    network: String(body?.network || "").trim().toLowerCase(),
    chargeFrom: body?.chargeFrom === "fiat" ? "fiat" : "crypto",
  };
}

/**
 * Sessionless payment estimate (no verifyEndUser check) — lets the send
 * flow show the crypto amount + fees before the user has logged in,
 * mirroring the existing public /v1/rate lookup the app already calls
 * directly. Still goes through this gateway (not called directly from the
 * app) because it's a /v1/payments/* route, signed with the same HMAC
 * secret as payment creation. Mirrors payment-engine's real
 * POST /v1/payments/estimate (src/routes/payment.routes.ts).
 */
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return json(res, 405, { ok: false, error: "Method not allowed" });
  }

  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);

  if (!apiKey || !secretKey) {
    return json(res, 500, {
      ok: false,
      error: "Payment estimate is not configured.",
    });
  }

  const payload = normalizePayload(req.body || {});
  const hasFiat = payload.fiatAmount !== undefined;
  const hasCrypto = payload.cryptoAmount !== undefined;
  if (!hasFiat && !hasCrypto) {
    return json(res, 400, { ok: false, error: "Either fiatAmount or cryptoAmount is required." });
  }
  for (const field of ["fiatAmount", "cryptoAmount"]) {
    if (payload[field] !== undefined && (!Number.isFinite(payload[field]) || payload[field] <= 0)) {
      return json(res, 400, { ok: false, error: `Valid ${field} is required.` });
    }
  }
  if (!CRYPTO_CURRENCIES.has(payload.crypto)) {
    return json(res, 400, { ok: false, error: "A supported crypto is required." });
  }
  if (!NETWORKS.has(payload.network)) {
    return json(res, 400, { ok: false, error: "A supported network is required." });
  }

  const path = DEFAULT_UPSTREAM_PATH;
  const body = JSON.stringify(payload);
  const timestamp = buildTimestamp();
  const signature = signRequest({
    secretKey,
    method: "POST",
    path,
    timestamp,
    body,
  });

  try {
    const upstream = await fetchWithTimeout(UPSTREAM_URL, {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
        "x-api-key": apiKey,
        "x-timestamp": timestamp,
        "x-signature": signature,
      },
      body,
    });
    const data = await upstream.json().catch(() => ({}));

    if (!upstream.ok || data.success === false) {
      return json(res, upstream.status || 502, {
        ok: false,
        error:
          pickString(data, ["error", "message"]) ||
          "Unable to estimate payment.",
      });
    }

    const estimate = data.estimate || {};
    return json(res, 200, {
      ok: true,
      estimate: {
        cryptoAmount: pickString(estimate, ["cryptoAmount", "crypto_amount"]),
        crypto: pickString(estimate, ["crypto"]) || payload.crypto,
        network: pickString(estimate, ["network"]) || payload.network,
        fiatAmount: pickString(estimate, ["fiatAmount", "fiat_amount"]),
        fiatCurrency:
          pickString(estimate, ["fiatCurrency", "fiat_currency"]) ||
          payload.fiatCurrency,
        rate: pickString(estimate, ["rate"]),
        conversionFee: pickString(estimate, [
          "conversionFee",
          "conversion_fee",
        ]),
        processingFee: pickString(estimate, [
          "processingFee",
          "processing_fee",
          "networkFee",
          "network_fee",
        ]),
        chargeFrom: pickString(estimate, ["chargeFrom", "charge_from"]) || payload.chargeFrom,
        expiresAt: pickString(estimate, ["expiresAt", "expires_at"]),
      },
    });
  } catch {
    return json(res, 500, { ok: false, error: "Payment estimate failed." });
  }
}
