/// Security helpers shared by Edge Functions.

/// Constant-time equality. Returns false if lengths differ.
/// Use for header / shared-secret comparisons so timing oracles
/// can't leak the secret one character at a time.
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
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
    return { ok: false, reason: 'WEBHOOK_SECRET not configured' };
  }
  const provided = req.headers.get('x-webhook-secret') ?? '';
  if (!timingSafeEqual(provided, envSecret)) {
    return { ok: false, reason: 'invalid webhook secret' };
  }
  return { ok: true };
}
