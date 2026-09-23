import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  normalizeReference,
  normalizeDigits,
  fetchWithTimeout,
  includeDiagnostics,
} from "../../../../lib/signing.js";
import { verifyEndUser } from "../../../../lib/endUser.js";
import { fetchGiftValidity } from "../../../../lib/gift-lookup.js";

const UPSTREAM_BASE_URL = "https://api.2settle.io/v1/payments/gifts";
const DEFAULT_UPSTREAM_BASE_PATH = "/v1/payments/gifts";

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

function buildPayloadCandidates({ bankCode, accountNumber }) {
  return [
    {
      receiver: {
        bankCode,
        accountNumber,
      },
    },
    {
      receiver: {
        bank_code: bankCode,
        account_number: accountNumber,
      },
    },
    {
      bankCode,
      accountNumber,
    },
    {
      bank_code: bankCode,
      account_number: accountNumber,
    },
    {
      destination: {
        bankCode,
        accountNumber,
      },
    },
    {
      destination: {
        bank_code: bankCode,
        account_number: accountNumber,
      },
    },
    {
      settlement: {
        bankCode,
        accountNumber,
      },
    },
    {
      settlement: {
        bank_code: bankCode,
        account_number: accountNumber,
      },
    },
  ];
}

async function confirmClaimWithUpstream({
  apiKey,
  secretKey,
  authHeader,
  reference,
  bankCode,
  accountNumber,
}) {
  const encodedReference = encodeURIComponent(reference);
  const path = `${DEFAULT_UPSTREAM_BASE_PATH}/${encodedReference}/claim/confirm`;
  let lastResponse = null;

  for (const payload of buildPayloadCandidates({ bankCode, accountNumber })) {
    const body = JSON.stringify(payload);
    const timestamp = buildTimestamp();
    const signature = signRequest({
      secretKey,
      method: "POST",
      path,
      timestamp,
      body,
    });

    const upstream = await fetchWithTimeout(
      `${UPSTREAM_BASE_URL}/${encodedReference}/claim/confirm`,
      {
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
      }
    );
    const data = await upstream.json().catch(() => ({}));
    lastResponse = { upstream, data, path };

    if (upstream.ok) return lastResponse;

    const message = pickString(data, ["error", "message"]) || "";
    if (!/validation/i.test(message)) return lastResponse;
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
      error: "Gift claim is not configured.",
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

  const receiver = req.body?.receiver || {};
  const bankCode = normalizeDigits(receiver.bankCode || receiver.bank_code);
  const accountNumber = normalizeDigits(
    receiver.accountNumber || receiver.account_number
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

  const validity = await fetchGiftValidity(reference, apiKey, secretKey);
  if (!validity.checked) {
    return json(res, 502, {
      ok: false,
      reference,
      error: "Gift ID could not be verified.",
    });
  }
  if (!validity.valid) {
    return json(res, 409, {
      ok: false,
      reference,
      error: "This gift is no longer available to claim.",
    });
  }

  try {
    const result = await confirmClaimWithUpstream({
      apiKey,
      secretKey,
      authHeader,
      reference,
      bankCode,
      accountNumber,
    });
    const upstream = result?.upstream;
    const data = result?.data || {};
    const path = result?.path ||
      `${DEFAULT_UPSTREAM_BASE_PATH}/${encodeURIComponent(reference)}/claim/confirm`;

    if (!upstream?.ok) {
      return json(res, upstream?.status || 502, {
        ok: false,
        reference,
        error: pickString(data, ["error", "message"]) || "Gift claim could not be confirmed.",
        ...(includeDiagnostics() ? { diagnostics: proxyDiagnostics(path) } : {}),
      });
    }

    return json(res, 200, {
      ok: true,
      reference,
      status: pickString(data, ["status", "state"]) || "confirmed",
      result: data.data || data.result || data,
    });
  } catch {
    return json(res, 500, {
      ok: false,
      reference,
      error: "Gift claim failed.",
    });
  }
}
