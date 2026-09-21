import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  pickDeepString,
  findDeepValue,
  normalizeReference,
  fetchWithTimeout,
  includeDiagnostics,
} from "../../lib/signing.js";

const UPSTREAM_BASE_URL = "https://api.2settle.io/v1/payments";
const DEFAULT_UPSTREAM_BASE_PATH = "/v1/payments";

function proxyDiagnostics(path) {
  return {
    upstreamUrl: UPSTREAM_BASE_URL,
    signaturePath: path,
    timestampUnit: cleanEnv(process.env.TWOSETTLE_TIMESTAMP_UNIT) || "milliseconds",
    signatureMode: cleanEnv(process.env.TWOSETTLE_SIGNATURE_MODE) || "postman-bodyhash",
    signatureEncoding: cleanEnv(process.env.TWOSETTLE_SIGNATURE_ENCODING) || "hex",
    signaturePrefix: cleanEnv(process.env.TWOSETTLE_SIGNATURE_PREFIX) || "none",
  };
}

/**
 * Public gift-lookup endpoint (no auth, per design — used for shareable
 * receipt/claim links). Hardened: never forwards the raw upstream object,
 * only an explicit allowlist of normalized fields.
 */
export default async function handler(req, res) {
  if (req.method !== "GET") {
    return json(res, 405, { ok: false, error: "Method not allowed" });
  }

  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);

  if (!apiKey || !secretKey) {
    return json(res, 500, {
      ok: false,
      error: "Gift lookup is not configured.",
      missing: {
        TWOSETTLE_API_KEY: !apiKey,
        TWOSETTLE_SECRET_KEY: !secretKey,
      },
    });
  }

  const reference = normalizeReference(req.query?.reference);
  if (!reference) {
    return json(res, 400, {
      ok: false,
      error: "Valid gift reference is required. Use 2S-XXXXXX.",
    });
  }

  const encodedReference = encodeURIComponent(reference);
  const path = `${DEFAULT_UPSTREAM_BASE_PATH}/${encodedReference}`;
  const timestamp = buildTimestamp();
  const body = "{}";
  const signature = signRequest({
    secretKey,
    method: "GET",
    path,
    timestamp,
    body,
  });

  try {
    const upstream = await fetchWithTimeout(`${UPSTREAM_BASE_URL}/${encodedReference}`, {
      method: "GET",
      headers: {
        accept: "application/json",
        "x-api-key": apiKey,
        "x-timestamp": timestamp,
        "x-signature": signature,
      },
    });
    const data = await upstream.json().catch(() => ({}));

    if (!upstream.ok) {
      return json(res, upstream.status, {
        ok: false,
        valid: false,
        reference,
        error: pickString(data, ["error", "message"]) || "Gift ID could not be verified.",
        ...(includeDiagnostics() ? { diagnostics: proxyDiagnostics(path) } : {}),
      });
    }

    return json(res, 200, {
      ok: true,
      valid: data.valid !== false,
      reference,
      amount: pickDeepString(
        data,
        [
          "amount",
          "amountNgn",
          "amount_ngn",
          "fiatAmount",
          "fiat_amount",
          "settlementAmount",
          "settlement_amount",
          "value",
        ],
        ["data", "gift", "result", "payment"]
      ),
      currency:
        pickDeepString(
          data,
          [
            "currency",
            "fiatCurrency",
            "fiat_currency",
            "settlementCurrency",
            "settlement_currency",
          ],
          ["data", "gift", "result", "payment"]
        ) || "NGN",
      status: pickDeepString(data, ["status", "state"], ["data", "gift", "result", "payment"]),
      claimedBankName: findDeepValue(data, [
        "bankName",
        "bank_name",
        "receiverBankName",
        "receiver_bank_name",
        "settlementBankName",
        "settlement_bank_name",
        "destinationBankName",
        "destination_bank_name",
        "institutionName",
      ]),
      expiresAt: pickDeepString(data, ["expiresAt", "expires_at"], ["data", "gift", "result", "payment"]),
    });
  } catch {
    return json(res, 500, {
      ok: false,
      valid: false,
      reference,
      error: "Gift lookup failed.",
    });
  }
}
