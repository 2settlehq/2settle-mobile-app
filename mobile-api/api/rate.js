import { json, fetchWithTimeout, pickString } from "../lib/signing.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/rate";

/**
 * Proxies payment-engine's public rate lookup so the app calls our own
 * backend instead of a third-party domain directly from the client (the
 * direct call is same-origin-restricted on web and bypasses this gateway
 * entirely). No API key/signature needed — the upstream route is public
 * and returns the same payload unauthenticated.
 */
export default async function handler(req, res) {
  if (req.method !== "GET") {
    return json(res, 405, { ok: false, error: "Method not allowed" });
  }

  try {
    const upstream = await fetchWithTimeout(UPSTREAM_URL, {
      method: "GET",
      headers: { accept: "application/json" },
    });
    const data = await upstream.json().catch(() => ({}));

    if (!upstream.ok) {
      return json(res, upstream.status || 502, {
        ok: false,
        error: pickString(data, ["error", "message"]) || "Unable to fetch live rate.",
      });
    }

    const rawRate = data?.rate ?? data?.price ?? data?.value ?? data?.data?.rate;
    const rate = Number(String(rawRate ?? "").replace(/,/g, "").trim());
    if (!Number.isFinite(rate) || rate <= 0) {
      return json(res, 502, { ok: false, error: "Rate unavailable." });
    }

    return json(res, 200, { ok: true, rate });
  } catch {
    return json(res, 500, { ok: false, error: "Rate lookup failed." });
  }
}
