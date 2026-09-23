import { buildTimestamp, signRequest, fetchWithTimeout, pickString } from "./signing.js";

// Only expose fields needed for claim eligibility; /gifts/check returns a full row.
export async function fetchGiftValidity(reference, apiKey, secretKey) {
  const path = "/v1/gifts/check";
  const timestamp = buildTimestamp();
  const signature = signRequest({ secretKey, method: "GET", path, timestamp, body: "{}" });
  try {
    const upstream = await fetchWithTimeout(
      `https://api.2settle.io${path}?gift_id=${encodeURIComponent(reference)}`,
      {
        method: "GET",
        headers: {
          accept: "application/json",
          "x-api-key": apiKey,
          "x-timestamp": timestamp,
          "x-signature": signature,
        },
      }
    );
    if (!upstream.ok) return { checked: false, valid: false };
    const data = await upstream.json();
    if (data?.exists === false) {
      return { checked: true, exists: false, valid: false, claimed: false, status: "not_found" };
    }
    const gift = data?.user;
    if (data?.exists !== true || !gift || typeof gift !== "object" || Array.isArray(gift)) {
      return { checked: false, valid: false };
    }
    const giftStatus = (pickString(gift, ["gift_status"]) || "").toLowerCase();
    const paymentStatus = (pickString(gift, ["status"]) || "").toLowerCase();
    const claimed = giftStatus === "claimed";
    const valid = giftStatus === "not claimed" && paymentStatus === "successful";
    const status = claimed ? "claimed"
      : paymentStatus === "cancel" ? "cancelled"
      : valid ? "confirmed"
      : ["processing", "uncompleted"].includes(paymentStatus) || giftStatus === "pending" ? "pending"
      : "unavailable";
    return {
      checked: true,
      exists: true,
      valid,
      claimed,
      status,
      amount: pickString(gift, ["amount_payable", "estimate_amount"]),
      currency: "NGN",
    };
  } catch {
    return { checked: false, valid: false };
  }
}
