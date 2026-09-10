import { fetchWithTimeout, json } from "../../../../lib/signing.js";

const UPSTREAM_URL = "https://api.2settle.io/v1/users/auth/otp/verify";

/**
 * Thin pass-through to payment-engine's real end-user OTP verify endpoint.
 * Returns { success, data: { user, accessToken, refreshToken, expiresInSec } }
 * on success — the app stores this as its real session.
 */
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return json(res, 405, { success: false, error: "Method not allowed" });
  }

  try {
    const upstream = await fetchWithTimeout(UPSTREAM_URL, {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/json",
      },
      body: JSON.stringify(req.body || {}),
    });
    const data = await upstream.json().catch(() => ({}));
    return json(res, upstream.status, data);
  } catch {
    return json(res, 500, { success: false, error: "OTP verification failed." });
  }
}
