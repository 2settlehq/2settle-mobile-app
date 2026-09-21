import crypto from "node:crypto";

export function json(res, status, body) {
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  res.status(status).json(body);
}

export function cleanEnv(value) {
  return String(value || "")
    .trim()
    .replace(/^['"]|['"]$/g, "");
}

// Signing diagnostics (upstream URL, signature scheme/encoding/prefix) are
// useful while wiring up a new environment but hand an attacker the exact
// HMAC scheme to target for free — including pre-auth, on the public gift
// lookup route. Off by default; opt in per-environment for debugging only.
export function includeDiagnostics() {
  return cleanEnv(process.env.TWOSETTLE_DEBUG_DIAGNOSTICS) === "true";
}

export function hmac(secretKey, payload, encoding = "hex") {
  return crypto.createHmac("sha256", secretKey).update(payload).digest(encoding);
}

export function buildTimestamp() {
  const timestampUnit = cleanEnv(process.env.TWOSETTLE_TIMESTAMP_UNIT) || "milliseconds";
  return timestampUnit === "seconds"
    ? Math.floor(Date.now() / 1000).toString()
    : Date.now().toString();
}

export function signRequest({ secretKey, method, path, timestamp, body }) {
  const signatureMode = cleanEnv(process.env.TWOSETTLE_SIGNATURE_MODE) || "postman-bodyhash";
  const signatureEncoding = cleanEnv(process.env.TWOSETTLE_SIGNATURE_ENCODING) || "hex";

  if (signatureMode === "postman-bodyhash") {
    const bodyHash = crypto.createHash("sha256").update(body).digest("hex");
    const payload = `${timestamp}|${method}|${path}|${bodyHash}`;
    const hmacKey = crypto.createHash("sha256").update(secretKey).digest("hex");
    const digest = hmac(hmacKey, payload, signatureEncoding);
    return cleanEnv(process.env.TWOSETTLE_SIGNATURE_PREFIX) === "sha256"
      ? `sha256=${digest}`
      : digest;
  }

  const payload =
    signatureMode === "timestamp-dot-body"
      ? `${timestamp}.${body}`
      : [method, path, timestamp, body].join("\n");
  const digest = hmac(secretKey, payload, signatureEncoding);
  return cleanEnv(process.env.TWOSETTLE_SIGNATURE_PREFIX) === "sha256"
    ? `sha256=${digest}`
    : digest;
}

export function pickString(source, keys) {
  for (const key of keys) {
    const value = source?.[key];
    if (typeof value === "string" && value.trim()) return value.trim();
    if (typeof value === "number") return String(value);
  }
  return null;
}

export function pickDeepString(source, keys, containerKeys = ["data", "result"]) {
  const direct = pickString(source, keys);
  if (direct) return direct;

  for (const containerKey of containerKeys) {
    const nested = source?.[containerKey];
    if (nested && typeof nested === "object") {
      const nestedValue = pickString(nested, keys);
      if (nestedValue) return nestedValue;
    }
  }

  return null;
}

export function findDeepValue(source, keys) {
  if (!source || typeof source !== "object") return null;

  const direct = pickString(source, keys);
  if (direct) return direct;

  for (const value of Object.values(source)) {
    if (value && typeof value === "object") {
      const nested = findDeepValue(value, keys);
      if (nested) return nested;
    }
  }

  return null;
}

export function normalizeReference(value) {
  const raw = Array.isArray(value) ? value[0] : value;
  const cleaned = String(raw || "")
    .trim()
    .toUpperCase()
    .replace(/\s+/g, "")
    .replace(/^2S-?/, "");
  if (!/^[A-Z0-9]{6}$/.test(cleaned)) return null;
  return `2S-${cleaned}`;
}

export function normalizeDigits(value) {
  return String(value || "").replace(/\D/g, "");
}

export async function fetchWithTimeout(url, options = {}, timeoutMs = 10000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}
