import { json, cleanEnv, normalizeReference } from "../../../lib/signing.js";
import { fetchGiftValidity } from "../../../lib/gift-lookup.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return json(res, 405, { ok: false, error: "Method not allowed" });
  }
  const reference = normalizeReference(req.query?.reference);
  if (!reference) {
    return json(res, 400, { ok: false, error: "Valid gift reference is required. Use 2S-XXXXXX." });
  }
  const apiKey = cleanEnv(process.env.TWOSETTLE_API_KEY);
  const secretKey = cleanEnv(process.env.TWOSETTLE_SECRET_KEY);
  if (!apiKey || !secretKey) {
    return json(res, 500, { ok: false, valid: false, error: "Gift lookup is not configured." });
  }
  const result = await fetchGiftValidity(reference, apiKey, secretKey);
  if (!result.checked) {
    return json(res, 502, { ok: false, valid: false, reference, error: "Gift ID could not be verified." });
  }
  const { checked, ...gift } = result;
  return json(res, 200, { ok: true, reference, ...gift });
}
