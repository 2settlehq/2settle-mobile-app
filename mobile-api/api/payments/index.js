import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  fetchWithTimeout,
  includeDiagnostics,
} from "../../lib/signing.js";
import { verifyEndUser } from "../../lib/endUser.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/payments";
const DEFAULT_UPSTREAM_PATH = "/v1/payments";

function normalizePayload(body, endUser) {
  const payload = {
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

  // Receiver bank details — required for type 'transfer' (payment-engine
  // resolves accountName/bankName server-side via NUBAN; we only ever
  // forward what the client can legitimately supply).
  const bankCode = pickString(body?.receiver, ["bankCode"]);
  const accountNumber = pickString(body?.receiver, ["accountNumber"]);
  if (bankCode && accountNumber) {
    payload.receiver = { bankCode, accountNumber };
  }

  if (payload.type === "request") {
    // The caller receives the request; the payer is supplied at fulfillment.
    delete payload.payer;
    delete payload.crypto;
    delete payload.network;
    delete payload.chargeFrom;
    if (payload.receiver) payload.receiver.phone = endUser.phone;
    const description = pickString(body?.metadata, ["description"]);
    if (description) payload.metadata = { description };
  }
  return payload;
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
  if (["transfer", "request"].includes(payload.type) && !payload.receiver) {
    return json(res, 400, {
      ok: false,
      error: "Receiver bank details are required for transfers and requests.",
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

    if (!upstream.ok || data.success === false || data.ok === false) {
      return json(res, upstream.ok ? 502 : upstream.status, {
        ok: false,
        error:
          pickString(data, ["error", "message"]) ||
          "Payment could not be created.",
        ...(includeDiagnostics() ? { diagnostics: proxyDiagnostics(path) } : {}),
      });
    }

    // Explicit allowlist — never forward the raw upstream object (it can
    // carry internal/financial fields) or echo the request payload (it
    // carries payer identity). Fields here match exactly what the app's
    // create-gift flow reads from the response (see
    // create_gift_widget.dart's _paymentFromResponse/_continueToFunding).
    const created = data.data || data.payment || data.result || data;
    const charge = created.charge && typeof created.charge === "object"
      ? { fiat: created.charge.fiat, crypto: created.charge.crypto }
      : undefined;
    return json(res, 200, {
      ok: true,
      payment: {
        id: created.id,
        reference: created.reference,
        type: created.type,
        status: created.status,
        depositAddress: created.depositAddress,
        cryptoAmount: created.cryptoAmount,
        crypto: created.crypto,
        network: created.network,
        fiatAmount: created.fiatAmount,
        fiatCurrency: created.fiatCurrency,
        rate: created.rate,
        charge,
        transactionUsd: created.transactionUsd,
        expiresAt: created.expiresAt,
        confirmedAt: created.confirmedAt,
        settledAt: created.settledAt,
      },
    });
  } catch {
    return json(res, 500, {
      ok: false,
      error: "Payment creation failed.",
    });
  }
}
