'use client';

import { useState } from 'react';

const DISMISSED_KEY = 'medbuddy.dismissedMissAlerts';

function loadDismissed(): string[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = window.localStorage.getItem(DISMISSED_KEY);
    return raw ? (JSON.parse(raw) as string[]) : [];
  } catch {
    return [];
  }
}

function saveDismissed(ids: string[]): void {
  try {
    window.localStorage.setItem(DISMISSED_KEY, JSON.stringify(ids));
  } catch {
    // Ignore quota / disabled storage.
  }
}

export default function MissAlert({
  logId,
  patientName,
  missedAt,
}: {
  logId: string;
  patientName: string;
  missedAt: string;
}) {
  // Lazy init from localStorage — component is client-only (no SSR), so
  // syncing initial state with persisted dismissal avoids a render flash
  // and avoids the "useEffect didn't fire in time" race seen in tests.
  const [dismissed, setDismissed] = useState<boolean>(() =>
    loadDismissed().includes(logId),
  );

  if (dismissed) return null;

  const onDismiss = () => {
    const next = Array.from(new Set([...loadDismissed(), logId])).slice(-50);
    saveDismissed(next);
    setDismissed(true);
  };

  return (
    <div className="bg-warning/15 border border-warning rounded-2xl p-4 flex items-start gap-3">
      <div className="text-2xl">⚠️</div>
      <div className="flex-1">
        <p className="font-semibold text-ink">
          {patientName} missed a dose at {missedAt}
        </p>
        <p className="text-sm text-ink/70">
          Consider checking in, they may need a nudge.
        </p>
      </div>
      <button
        aria-label="Dismiss"
        onClick={onDismiss}
        className="text-ink/50 hover:text-ink"
      >
        ✕
      </button>
    </div>
  );
}
