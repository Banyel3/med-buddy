import type { ComplianceLog, ComplianceStatus } from '@/lib/supabase/types';

function colorFor(status: ComplianceStatus | 'upcoming'): string {
  switch (status) {
    case 'verified':
      return 'bg-secondary';
    case 'late':
      return 'bg-warning';
    case 'missed':
      return 'bg-danger/40';
    case 'pending':
      return 'bg-surface-container';
    default:
      return 'bg-surface border border-outline';
  }
}

export default function ComplianceCalendar({
  logs,
}: {
  logs: ComplianceLog[];
}) {
  const today = new Date();
  const first = new Date(today.getFullYear(), today.getMonth(), 1);
  const next = new Date(today.getFullYear(), today.getMonth() + 1, 1);
  const daysInMonth = Math.round(
    (next.getTime() - first.getTime()) / (1000 * 60 * 60 * 24),
  );
  const days = Array.from({ length: daysInMonth }, (_, i) => {
    const d = new Date(first);
    d.setDate(first.getDate() + i);
    return d;
  });

  return (
    <div className="bg-white rounded-3xl border border-outline p-5">
      <h3 className="text-lg font-bold text-ink mb-3">
        {first.toLocaleString('en-US', { month: 'long', year: 'numeric' })}
      </h3>
      <div className="grid grid-cols-7 gap-2">
        {days.map((d) => {
          const key = d.toISOString().slice(0, 10);
          const log = logs.find((l) => l.date === key);
          const isFuture = d > today;
          const status = isFuture ? 'upcoming' : log?.status ?? 'missed';
          return (
            <div
              key={key}
              className={`aspect-square rounded-lg flex items-center justify-center text-xs font-semibold ${colorFor(
                status,
              )} ${status === 'verified' || status === 'late' ? 'text-white' : 'text-ink/80'}`}
              title={`${key} — ${status}`}
            >
              {d.getDate()}
            </div>
          );
        })}
      </div>
      <div className="flex gap-4 mt-3 text-xs text-ink/70">
        <Legend color="bg-secondary" label="Verified" />
        <Legend color="bg-warning" label="Late" />
        <Legend color="bg-danger/40" label="Missed" />
      </div>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <div className="flex items-center gap-1">
      <span className={`inline-block w-3 h-3 rounded-sm ${color}`} />
      <span>{label}</span>
    </div>
  );
}
