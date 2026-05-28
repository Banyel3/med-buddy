// Pure helpers used by daily-rollover (and unit-tested in _tests/).

export function shouldResetStreak(
  lastVerifiedDate: Date | null,
  now: Date,
): boolean {
  if (lastVerifiedDate === null) return false;
  const yesterday = new Date(now);
  yesterday.setUTCHours(0, 0, 0, 0);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  return lastVerifiedDate < yesterday;
}

export function nextLongestStreak(
  currentStreak: number,
  longestStreak: number,
): number {
  return Math.max(currentStreak ?? 0, longestStreak ?? 0);
}

export function isPhotoExpired(
  createdAt: Date | null,
  retentionDays: number,
  now: Date,
): boolean {
  if (createdAt === null) return false;
  const cutoff = new Date(now);
  cutoff.setUTCDate(cutoff.getUTCDate() - retentionDays);
  return createdAt < cutoff;
}
