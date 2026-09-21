import {
  json,
  cleanEnv,
  buildTimestamp,
  signRequest,
  pickString,
  normalizeReference,
  fetchWithTimeout,
  includeDiagnostics,
} from "../../../../lib/signing.js";
import { verifyEndUser, callerOwnsReference } from "../../../../lib/endUser.js";

const UPSTREAM_BASE_URL = "https://api.2settle.io/v1/payment";
const DEFAULT_UPSTREAM_BASE_PATH = "/v1/payment";

function proxyDiagnostics(path) {
  return {
    upstreamUrl: UPSTREAM_BASE_URL,
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

  const reference = normalizeReference(req.query?.reference);
  if (!reference) {
    return json(res, 400, {
      ok: false,
      error: "Valid gift reference is required. Use 2S-XXXXXX.",
    });
  }

  const owns = await callerOwnsReference(authHeader, reference);
  if (!owns) {
    return json(res, 403, {
      ok: false,
      reference,
      error: "You do not have permission to cancel this payment.",
    });
  }

  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);

  if (!apiKey || !secretKey) {
    return json(res, 500, {
      ok: false,
      error: "Gift cancellation is not configured.",
      missing: {
        TWOSETTLE_API_KEY: !apiKey,
        TWOSETTLE_SECRET_KEY: !secretKey,
      },
    });
  }

  const encodedReference = encodeURIComponent(reference);
  const path = `${DEFAULT_UPSTREAM_BASE_PATH}/${encodedReference}/cancel`;
  const body = "{}";
  const timestamp = buildTimestamp();
  const signature = signRequest({
    secretKey,
    method: "POST",
    path,
    timestamp,
    body,
  });

  try {
    const upstream = await fetchWithTimeout(
      `${UPSTREAM_BASE_URL}/${encodedReference}/cancel`,
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

    if (!upstream.ok) {
      return json(res, upstream.status, {
        ok: false,
        reference,
        error:
          pickString(data, ["error", "message"]) ||
          "Gift could not be cancelled.",
        ...(includeDiagnostics() ? { diagnostics: proxyDiagnostics(path) } : {}),
      });
    }

    return json(res, 200, {
      ok: true,
      reference,
      status: pickString(data, ["status", "state"]) || "cancelled",
      result: data.data || data.result || data.payment || data,
    });
  } catch {
    return json(res, 500, {
      ok: false,
      reference,
      error: "Gift cancellation failed.",
    });
  }
}
