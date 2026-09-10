import { fetchWithTimeout } from "./signing.js";

const USERS_ME_URL = "https://api.2settle.io/v1/users/me";
const USERS_ME_PAYMENTS_URL = "https://api.2settle.io/v1/users/me/payments";

/**
 * Verifies a caller's bearer token against payment-engine's existing,
 * unmodified GET /v1/users/me route and returns their identity, or null
 * if the token is missing/invalid/expired. No payment-engine changes
 * needed — this just calls what's already there.
 */
export async function verifyEndUser(authHeader) {
  if (!authHeader) return null;

  try {
    const upstream = await fetchWithTimeout(USERS_ME_URL, {
      method: "GET",
      headers: { accept: "application/json", authorization: authHeader },
    });
    if (!upstream.ok) return null;

    const data = await upstream.json().catch(() => ({}));
    const user = data?.data?.user;
    if (!user?.id) return null;

    const identities = data?.data?.identities || [];
    const phone =
      identities.find((identity) => identity.type === "phone" && identity.verifiedAt)
        ?.identifier || null;

    return { id: user.id, phone };
  } catch {
    return null;
  }
}

/**
 * Confirms the caller is the sender/payer of the given reference, using
 * payment-engine's existing GET /v1/users/me/payments (already matches by
 * the caller's verified phone identities against payer/receiver phone).
 * Paginates up to a safety cap rather than assuming everyone fits on one page.
 */
export async function callerOwnsReference(authHeader, reference, { maxPages = 5, pageSize = 200 } = {}) {
  for (let page = 0; page < maxPages; page++) {
    const offset = page * pageSize;
    let upstream;
    try {
      upstream = await fetchWithTimeout(
        `${USERS_ME_PAYMENTS_URL}?limit=${pageSize}&offset=${offset}`,
        { method: "GET", headers: { accept: "application/json", authorization: authHeader } }
      );
    } catch {
      return false;
    }
    if (!upstream.ok) return false;

    const data = await upstream.json().catch(() => ({}));
    const payments = data?.data?.payments || [];
    const match = payments.find(
      (payment) =>
        payment.reference === reference &&
        (payment.direction === "sent" || payment.direction === "both")
    );
    if (match) return true;

    const total = data?.data?.total ?? payments.length;
    if (offset + payments.length >= total || payments.length === 0) break;
  }

  return false;
}
