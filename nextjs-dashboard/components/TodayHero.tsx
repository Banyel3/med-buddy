import type { ComplianceStatus } from '@/lib/supabase/types';

function formatTime(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return 'an unknown time';
  return d.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

export default function TodayHero({
  status,
  patientName,
  skippedAt,
}: {
  status: ComplianceStatus | 'no-log';
  patientName: string;
  /** ISO timestamp when they said they couldn't take this dose. */
  skippedAt?: string | null;
}) {
  const map: Record<
    string,
    { label: string; sub: string; bg: string; emoji: string }
  > = {
    verified: {
      label: 'Verified',
      sub: `${patientName} took today's dose.`,
      bg: 'bg-secondary',
      emoji: '✅',
    },
    pending: {
      label: 'Pending',
      sub: 'Waiting on verification.',
      bg: 'bg-warning',
      emoji: '⏳',
    },
    late: {
      label: 'Late',
      sub: 'Dose was taken late.',
      bg: 'bg-warning',
      emoji: '⏰',
    },
    missed: {
      label: 'Missed',
      // A dose actively declined reads very differently to a worried
      // reader than one that was simply never logged. Same status,
      // different sentence.
      sub: skippedAt
        ? `${patientName} said they couldn't take it at ${formatTime(skippedAt)}.`
        : `${patientName} hasn't logged today's dose.`,
      bg: 'bg-danger',
      emoji: '❗',
    },
    'no-log': {
      label: 'No log yet',
      sub: "We'll show today's dose status as soon as it's logged.",
      bg: 'bg-primary',
      emoji: '💊',
    },
  };
  const v = map[status];
  return (
    <div className={`${v.bg} text-white rounded-3xl p-6 shadow-lg`}>
      <div className="text-4xl">{v.emoji}</div>
      <div className="mt-3 text-3xl font-extrabold">{v.label}</div>
      <div className="opacity-90 text-sm mt-1">{v.sub}</div>
    </div>
  );
}
