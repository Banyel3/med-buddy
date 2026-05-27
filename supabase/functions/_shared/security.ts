/// Security helpers shared by Edge Functions.

/// Constant-time equality. Does NOT short-circuit on length mismatch
/// (early-exit would leak the secret length via response time).
/// Loop bound is max(a, b); mismatched length forces diff != 0
/// because charCodeAt past the end returns NaN, so NaN^x = NaN,
/// and we add that into diff via an explicit length-or guard.
export function timingSafeEqual(a: string, b: string): boolean {
  const len = Math.max(a.length, b.length);
  let diff = a.length ^ b.length;
  for (let i = 0; i < len; i++) {
    const ca = i < a.length ? a.charCodeAt(i) : 0;
    const cb = i < b.length ? b.charCodeAt(i) : 0;
    diff |= ca ^ cb;
  }
  return diff === 0;
}

/// Pulls the `x-webhook-secret` header off the request and
/// constant-time compares it to the configured WEBHOOK_SECRET env.
/// Returns { ok: true } on match, { ok: false, reason } otherwise.
export function checkWebhookSecret(
  req: Request,
  envSecret: string | undefined,
): { ok: boolean; reason?: string } {
  if (!envSecret || envSecret.length < 16) {
    return { ok: false, reason: "WEBHOOK_SECRET not configured" };
  }
  const provided = req.headers.get("x-webhook-secret") ?? "";
  if (!timingSafeEqual(provided, envSecret)) {
    return { ok: false, reason: "invalid webhook secret" };
  }
  return { ok: true };
}
