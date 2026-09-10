import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  fetchWithTimeout,
} from "../../lib/signing.js";
import { verifyEndUser } from "../../lib/endUser.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/payments";
const DEFAULT_UPSTREAM_PATH = "/v1/payments";

function normalizePayload(body, endUser) {
  return {
    type: body?.type || "gift",
    fiatAmount: Number(body?.fiatAmount),
    chargeFrom: body?.chargeFrom || "fiat",
    fiatCurrency: body?.fiatCurrency || "NGN",
    crypto: body?.crypto || "USDT",
    network: body?.network || "erc20",
    // Payer identity is derived from the verified caller, never trusted
    // from the client — closes the "anyone can claim any identity" gap.
    payer: {
      chatId: endUser.id,
      phone: endUser.phone,
    },
  };
}

function proxyDiagnostics(path) {
  return {
    upstreamUrl: UPSTREAM_URL,
    signaturePath: path,
    timestampUnit:
      cleanEnv(process.env.TWOSETTLE_TIMESTAMP_UNIT) || "milliseconds",
    signatureMode:
      cleanEnv(process.env.TWOSETTLE_SIGNATURE_MODE) || "postman-bodyhash",
    signatureEncoding:
      cleanEnv(process.env.TWOSETTLE_SIGNATURE_ENCODING) || "hex",
    signaturePrefix: cleanEnv(process.env.TWOSETTLE_SIGNATURE_PREFIX) || "none",
  };
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return json(res, 405, { ok: false, error: "Method not allowed" });
  }

  const authHeader = req.headers?.authorization || req.headers?.Authorization;
  if (!authHeader) {
    return json(res, 401, { ok: false, error: "Authentication required." });
  }

  const endUser = await verifyEndUser(authHeader);
  if (!endUser) {
    return json(res, 401, { ok: false, error: "Invalid or expired session." });
  }
  if (!endUser.phone) {
    return json(res, 400, {
      ok: false,
      error: "Your account has no verified phone number.",
    });
  }

  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);

  if (!apiKey || !secretKey) {
    return json(res, 500, {
      ok: false,
      error: "Payment creation is not configured.",
      missing: {
        TWOSETTLE_API_KEY: !apiKey,
        TWOSETTLE_SECRET_KEY: !secretKey,
      },
    });
  }

  const payload = normalizePayload(req.body || {}, endUser);
  if (!Number.isFinite(payload.fiatAmount) || payload.fiatAmount <= 0) {
    return json(res, 400, {
      ok: false,
      error: "Valid fiatAmount is required.",
    });
  }

  const path = cleanEnv(process.env.TWOSETTLE_PAYMENTS_SIGNATURE_PATH) ||
    DEFAULT_UPSTREAM_PATH;
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
        authorization: authHeader,
      },
      body,
    });
    const data = await upstream.json().catch(() => ({}));

    if (!upstream.ok) {
      return json(res, upstream.status, {
        ok: false,
        error:
          pickString(data, ["error", "message"]) ||
          "Payment could not be created.",
        request: payload,
        diagnostics: proxyDiagnostics(path),
        upstream: data,
      });
    }

    return json(res, 200, {
      ok: true,
      request: payload,
      payment: data.data || data.payment || data.result || data,
      raw: data,
    });
  } catch {
    return json(res, 500, {
      ok: false,
      error: "Payment creation failed.",
      request: payload,
    });
  }
}
