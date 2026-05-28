import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  isPhotoExpired,
  nextLongestStreak,
  shouldResetStreak,
} from "../_shared/streak_math.ts";

Deno.test("shouldResetStreak: null last_verified_date returns false", () => {
  assertEquals(
    shouldResetStreak(null, new Date("2026-05-24T12:00:00Z")),
    false,
  );
});

Deno.test("shouldResetStreak: last_verified yesterday returns false (still in grace)", () => {
  const now = new Date("2026-05-24T12:00:00Z");
  const yesterday = new Date("2026-05-23T00:00:00Z");
  assertEquals(shouldResetStreak(yesterday, now), false);
});

Deno.test("shouldResetStreak: last_verified two days ago returns true", () => {
  const now = new Date("2026-05-24T12:00:00Z");
  const twoAgo = new Date("2026-05-22T00:00:00Z");
  assertEquals(shouldResetStreak(twoAgo, now), true);
});

Deno.test("shouldResetStreak: last_verified today returns false", () => {
  const now = new Date("2026-05-24T12:00:00Z");
  const today = new Date("2026-05-24T03:00:00Z");
  assertEquals(shouldResetStreak(today, now), false);
});

Deno.test("nextLongestStreak: keeps existing longest when current is smaller", () => {
  assertEquals(nextLongestStreak(3, 10), 10);
});

Deno.test("nextLongestStreak: promotes current when greater than longest", () => {
  assertEquals(nextLongestStreak(15, 10), 15);
});

Deno.test("nextLongestStreak: handles 0 + 0", () => {
  assertEquals(nextLongestStreak(0, 0), 0);
});

Deno.test("isPhotoExpired: null created_at returns false", () => {
  assertEquals(isPhotoExpired(null, 30, new Date()), false);
});

Deno.test("isPhotoExpired: 31-day-old photo is expired at 30-day TTL", () => {
  const now = new Date("2026-05-24T00:00:00Z");
  const old = new Date("2026-04-23T00:00:00Z"); // 31 days back
  assertEquals(isPhotoExpired(old, 30, now), true);
});

Deno.test("isPhotoExpired: 1-day-old photo is fresh at 30-day TTL", () => {
  const now = new Date("2026-05-24T00:00:00Z");
  const fresh = new Date("2026-05-23T00:00:00Z");
  assertEquals(isPhotoExpired(fresh, 30, now), false);
});

Deno.test("isPhotoExpired: exact boundary (30 days old, hours match) returns false", () => {
  const now = new Date("2026-05-24T00:00:00Z");
  const boundary = new Date("2026-04-24T00:00:00Z");
  assertEquals(isPhotoExpired(boundary, 30, now), false);
});
