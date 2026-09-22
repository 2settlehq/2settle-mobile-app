export function safeErrorText(value) {
  if (typeof value !== "string") return undefined;
  let text = value;
  for (const [key, secret] of Object.entries(process.env)) {
    if (/secret|token|password|api_?key|pin/i.test(key) && secret && secret.length >= 4) {
      text = text.split(secret).join("[REDACTED]");
    }
  }
  return text
    .replace(/https?:\/\/\S+/gi, "[URL REDACTED]")
    .replace(/Bearer\s+\S+/gi, "Bearer [REDACTED]")
    .replace(/(?:token|secret|password|pin|api[_-]?key|authorization|signature)\s*[=:]\s*["']?[^\s,"';}]+/gi, "[CREDENTIAL REDACTED]")
    .replace(/\b[A-Za-z0-9_-]{24,}(?:\.[A-Za-z0-9_-]+)*\b/g, "[REDACTED]")
    .replace(/\b\d{4,}\b/g, "[REDACTED]")
    .replace(/\b[\w.+-]+@[\w.-]+\.[A-Za-z]+\b/g, "[EMAIL REDACTED]")
    .replace(/[\r\n]/g, " ").slice(0, 2000);
}

export function errorFields(body) {
  return {
    code: safeErrorText(body?.code),
    message: safeErrorText(body?.error) || safeErrorText(body?.message),
    // Log validation field names, never rejected input values.
    fields: body?.details?.fieldErrors && typeof body.details.fieldErrors === "object"
      ? Object.keys(body.details.fieldErrors).map(safeErrorText) : undefined,
  };
}
