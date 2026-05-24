import { redirect } from 'next/navigation';

import ComplianceCalendar from '@/components/ComplianceCalendar';
import MissAlert from '@/components/MissAlert';
import PhotoGrid from '@/components/PhotoGrid';
import RealtimeBridge from '@/components/RealtimeBridge';
import StreakWidget from '@/components/StreakWidget';
import TodayHero from '@/components/TodayHero';
import VelocityChart from '@/components/VelocityChart';
import { supabaseServer } from '@/lib/supabase/server';
import type { ComplianceLog, Streak } from '@/lib/supabase/types';

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const supabase = supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  // Resolve linked patient(s) via monitor_links.
  const { data: links } = await supabase
    .from('monitor_links')
    .select('patient_id')
    .eq('monitor_id', user.id);

  const patientId = links?.[0]?.patient_id;
  if (!patientId) {
    return <NoPatientLinked email={user.email ?? ''} />;
  }

  const [{ data: patient }, { data: logs }, { data: streak }] =
    await Promise.all([
      supabase.from('users').select('*').eq('id', patientId).maybeSingle(),
      supabase
        .from('compliance_logs')
        .select('*')
        .eq('user_id', patientId)
        .order('date', { ascending: false })
        .limit(120),
      supabase
        .from('streaks')
        .select('*')
        .eq('user_id', patientId)
        .maybeSingle(),
    ]);

  const allLogs: ComplianceLog[] = (logs as ComplianceLog[]) ?? [];
  const streakRow = (streak as Streak | null) ?? null;
  const todayKey = new Date().toISOString().slice(0, 10);
  const todayLog = allLogs.find((l) => l.date === todayKey);
  const todayStatus = todayLog?.status ?? 'no-log';
  const latestMiss = allLogs.find((l) => l.status === 'missed');

  return (
    <main className="min-h-screen bg-surface">
      <RealtimeBridge patientId={patientId} />
      <header className="bg-white border-b border-outline">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl">💊</span>
            <div>
              <div className="font-extrabold text-ink">MedBuddy Monitor</div>
              <div className="text-xs text-ink/60">
                Watching: {patient?.name ?? 'Patient'}
              </div>
            </div>
          </div>
          <form action="/api/signout" method="post">
            <button className="text-sm text-ink/60 hover:text-ink">
              Sign out
            </button>
          </form>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-8 space-y-6">
        {latestMiss && (
          <MissAlert
            patientName={patient?.name ?? 'Patient'}
            missedAt={latestMiss.date}
          />
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <TodayHero
            status={todayStatus}
            patientName={patient?.name ?? 'Patient'}
          />
          <StreakWidget streak={streakRow} />
          <VelocityChart logs={allLogs.slice(0, 30)} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <ComplianceCalendar logs={allLogs} />
          </div>
          <PhotoGrid logs={allLogs} />
        </div>
      </div>
    </main>
  );
}

function NoPatientLinked({ email }: { email: string }) {
  return (
    <main className="min-h-screen bg-surface flex items-center justify-center px-6">
      <div className="bg-white rounded-4xl border border-outline p-10 max-w-md text-center space-y-4">
        <div className="text-5xl">🔗</div>
        <h1 className="text-2xl font-extrabold text-ink">
          No patient linked yet
        </h1>
        <p className="text-ink/70 text-sm">
          You&apos;re signed in as <strong>{email}</strong>. Ask your
          patient to share their MedBuddy link code, then a row in{' '}
          <code>monitor_links</code> will appear here.
        </p>
      </div>
    </main>
  );
}
