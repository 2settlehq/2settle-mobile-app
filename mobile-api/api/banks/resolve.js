import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  pickDeepString,
  fetchWithTimeout,
  includeDiagnostics,
} from "../../lib/signing.js";
import { verifyEndUser } from "../../lib/endUser.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/banks/resolve";
const DEFAULT_UPSTREAM_PATH = "/v1/banks/resolve";

function normalizeDigits(value) {
  return String(value || "").replace(/\D/g, "");
}

function buildPayload({ bankCode, accountNumber }) {
  const bodyStyle = cleanEnv(process.env.TWOSETTLE_BODY_STYLE) || "snake";

  if (bodyStyle === "snake") {
    return { bank_code: bankCode, account_number: accountNumber };
  }

  if (bodyStyle === "both") {
    return { bankCode, accountNumber, bank_code: bankCode, account_number: accountNumber };
  }

  return { bankCode, accountNumber };
}

function buildPayloadCandidates({ bankCode, accountNumber }) {
  const bodyStyle = cleanEnv(process.env.TWOSETTLE_BODY_STYLE);

  return bodyStyle
    ? [buildPayload({ bankCode, accountNumber })]
    : [{ bank_code: bankCode, account_number: accountNumber }];
}

function resolverDiagnostics() {
  return {
    upstreamUrl: UPSTREAM_URL,
    signaturePath: cleanEnv(process.env.TWOSETTLE_SIGNATURE_PATH) || DEFAULT_UPSTREAM_PATH,
    timestampUnit: cleanEnv(process.env.TWOSETTLE_TIMESTAMP_UNIT) || "milliseconds",
    bodyStyle: cleanEnv(process.env.TWOSETTLE_BODY_STYLE) || "snake",
    signatureMode:
      cleanEnv(process.env.TWOSETTLE_SIGNATURE_MODE) ||
      "postman-bodyhash",
    signatureEncoding: cleanEnv(process.env.TWOSETTLE_SIGNATURE_ENCODING) || "hex",
    signaturePrefix: cleanEnv(process.env.TWOSETTLE_SIGNATURE_PREFIX) || "none",
  };
}

async function resolveWithUpstream({ apiKey, secretKey, authHeader, bankCode, accountNumber }) {
  const path = cleanEnv(process.env.TWOSETTLE_SIGNATURE_PATH) || DEFAULT_UPSTREAM_PATH;
  let lastResponse = null;

  for (const payload of buildPayloadCandidates({ bankCode, accountNumber })) {
    const timestamp = buildTimestamp();
    const body = JSON.stringify(payload);
    const signature = signRequest({
      secretKey,
      method: "POST",
      path,
      timestamp,
      body,
    });

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
    lastResponse = { upstream, data };

    const message = pickString(data, ["error", "message"]) || "";
    if (!(upstream.status === 401 && /signature/i.test(message))) {
      return lastResponse;
    }
  }

  return lastResponse;
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

  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);

  if (!apiKey || !secretKey) {
    return json(res, 500, {
      ok: false,
      error: "Bank resolver is not configured.",
      missing: {
        TWOSETTLE_API_KEY: !apiKey,
        TWOSETTLE_SECRET_KEY: !secretKey,
      },
    });
  }

  try {
    const bankCode = normalizeDigits(req.body?.bankCode || req.body?.bank_code);
    const accountNumber = normalizeDigits(
      req.body?.accountNumber || req.body?.account_number
    );

    if (!/^\d{6}$/.test(bankCode)) {
      return json(res, 400, {
        ok: false,
        error: "Valid 6-digit bank code is required.",
      });
    }

    if (!/^\d{10}$/.test(accountNumber)) {
      return json(res, 400, {
        ok: false,
        error: "Valid 10-digit account number is required.",
      });
    }

    const resolved = await resolveWithUpstream({
      apiKey,
      secretKey,
      authHeader,
      bankCode,
      accountNumber,
    });

    const upstream = resolved?.upstream;
    const data = resolved?.data || {};

    if (!upstream?.ok) {
      return json(res, upstream?.status || 502, {
        ok: false,
        error:
          pickString(data, ["error", "message"]) ||
          "Unable to resolve bank account.",
        ...(includeDiagnostics() ? { diagnostics: resolverDiagnostics() } : {}),
      });
    }

    return json(res, 200, {
      ok: true,
      valid: data.valid !== false,
      accountName: pickDeepString(data, [
        "accountName",
        "account_name",
        "account_name_enquiry",
        "account_name_enquiry_result",
        "account_holder_name",
        "accountHolderName",
        "name",
      ], ["data", "result", "account", "recipient"]),
      bankName: pickDeepString(
        data,
        ["bankName", "bank_name", "bank", "institutionName"],
        ["data", "result", "account", "recipient"]
      ),
      bankCode,
      accountNumber,
    });
  } catch {
    return json(res, 500, {
      ok: false,
      error: "Bank resolution failed.",
    });
  }
}
