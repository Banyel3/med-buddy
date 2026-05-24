import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';

// Verifies the no-op contract: miss-alert only fires when status === 'missed'.
// Pure logic extracted for testability.

export function shouldFireMissAlert(record: { status: string }): boolean {
  return record.status === 'missed';
}

Deno.test('miss-alert: ignores verified status', () => {
  assertEquals(shouldFireMissAlert({ status: 'verified' }), false);
});

Deno.test('miss-alert: ignores pending status', () => {
  assertEquals(shouldFireMissAlert({ status: 'pending' }), false);
});

Deno.test('miss-alert: ignores late status', () => {
  assertEquals(shouldFireMissAlert({ status: 'late' }), false);
});

Deno.test('miss-alert: fires on missed status', () => {
  assertEquals(shouldFireMissAlert({ status: 'missed' }), true);
});
