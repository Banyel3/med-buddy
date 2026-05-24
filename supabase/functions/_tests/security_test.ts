import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  checkWebhookSecret,
  timingSafeEqual,
} from '../_shared/security.ts';

Deno.test('timingSafeEqual: equal strings → true', () => {
  assertEquals(timingSafeEqual('abc123', 'abc123'), true);
});

Deno.test('timingSafeEqual: different content same length → false', () => {
  assertEquals(timingSafeEqual('abc123', 'abc124'), false);
});

Deno.test('timingSafeEqual: different lengths → false', () => {
  assertEquals(timingSafeEqual('abc', 'abc1'), false);
});

Deno.test('timingSafeEqual: empty strings → true', () => {
  assertEquals(timingSafeEqual('', ''), true);
});

function reqWithHeader(value?: string): Request {
  const h = new Headers();
  if (value !== undefined) h.set('x-webhook-secret', value);
  return new Request('http://x/', { method: 'POST', headers: h });
}

Deno.test('checkWebhookSecret: missing env → ok=false', () => {
  const r = checkWebhookSecret(reqWithHeader('whatever'), undefined);
  assertEquals(r.ok, false);
  assertEquals(r.reason, 'WEBHOOK_SECRET not configured');
});

Deno.test('checkWebhookSecret: short env (<16 chars) → ok=false', () => {
  const r = checkWebhookSecret(reqWithHeader('short'), 'short');
  assertEquals(r.ok, false);
  assertEquals(r.reason, 'WEBHOOK_SECRET not configured');
});

Deno.test('checkWebhookSecret: missing header → ok=false', () => {
  const r = checkWebhookSecret(reqWithHeader(), 'a'.repeat(32));
  assertEquals(r.ok, false);
  assertEquals(r.reason, 'invalid webhook secret');
});

Deno.test('checkWebhookSecret: wrong header → ok=false', () => {
  const secret = 'a'.repeat(32);
  const r = checkWebhookSecret(reqWithHeader('b'.repeat(32)), secret);
  assertEquals(r.ok, false);
});

Deno.test('checkWebhookSecret: matching header → ok=true', () => {
  const secret = 'a'.repeat(32);
  const r = checkWebhookSecret(reqWithHeader(secret), secret);
  assertEquals(r.ok, true);
});
