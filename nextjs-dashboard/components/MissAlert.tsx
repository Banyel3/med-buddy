'use client';

import { useState } from 'react';

export default function MissAlert({
  patientName,
  missedAt,
}: {
  patientName: string;
  missedAt: string;
}) {
  const [open, setOpen] = useState(true);
  if (!open) return null;
  return (
    <div className="bg-warning/15 border border-warning rounded-2xl p-4 flex items-start gap-3">
      <div className="text-2xl">⚠️</div>
      <div className="flex-1">
        <p className="font-semibold text-ink">
          {patientName} missed a dose at {missedAt}
        </p>
        <p className="text-sm text-ink/70">
          Consider checking in — they may need a nudge.
        </p>
      </div>
      <button
        aria-label="Dismiss"
        onClick={() => setOpen(false)}
        className="text-ink/50 hover:text-ink"
      >
        ✕
      </button>
    </div>
  );
}
