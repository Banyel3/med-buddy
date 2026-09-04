import { createClient } from '@supabase/supabase-js';
import { redirect } from 'next/navigation';

import ComplianceCalendar from '@/components/ComplianceCalendar';
import LinkPatientForm from '@/components/LinkPatientForm';
import MissAlert from '@/components/MissAlert';
import PhotoGrid from '@/components/PhotoGrid';
import RealtimeBridge from '@/components/RealtimeBridge';
import StreakWidget from '@/components/StreakWidget';
import TodayHero from '@/components/TodayHero';
import VelocityChart from '@/components/VelocityChart';
import { supabaseServer } from '@/lib/supabase/server';
import type { ComplianceLog, Streak } from '@/lib/supabase/types';

export const dynamic = 'force-dynamic';

const SIGNED_URL_TTL_SECONDS = 3600;

export default async function DashboardPage() {
  const supabase = supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  // Role gate — mobile-app accounts land here when they sign in to the
  // wrong surface.
  // Sign out + redirect to /login with a query flag so the form can render
  // a clear message; without the signOut() we'd loop via app/page.tsx
  // (which redirects authenticated users straight back to /dashboard).
  const { data: profile } = await supabase
    .from('users')
    .select('role')
    .eq('id', user.id)
    .maybeSingle();
  if (profile?.role !== 'monitor') {
    await supabase.auth.signOut();
    redirect('/login?error=monitor_only');
  }

  // Resolve the linked account via monitor_links.
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

  const rawLogs: ComplianceLog[] = (logs as ComplianceLog[]) ?? [];
  const allLogs = await signLogImageUrls(rawLogs);

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
              <div className="font-extrabold text-ink">MedBuddy</div>
              <div className="text-xs text-ink/60">
                {patient?.name ?? 'Not linked yet'}
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
            logId={latestMiss.id}
            patientName={patient?.name ?? 'Your person'}
            missedAt={latestMiss.date}
          />
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <TodayHero
            skippedAt={todayLog?.skipped_at ?? null}
            status={todayStatus}
            patientName={patient?.name ?? 'Your person'}
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

async function signLogImageUrls(
  logs: ComplianceLog[],
): Promise<ComplianceLog[]> {
  const needsSigning = logs.some((l) => l.image_url);
  if (!needsSigning) return logs;

  const admin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );

  return Promise.all(
    logs.map(async (log) => {
      if (!log.image_url) return log;
      const path = extractStoragePath(log.image_url);
      if (!path) return { ...log, image_url: null };
      const { data, error } = await admin.storage
        .from('verifications')
        .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
      if (error || !data?.signedUrl) {
        return { ...log, image_url: null };
      }
      return { ...log, image_url: data.signedUrl };
    }),
  );
}

function extractStoragePath(urlOrPath: string): string | null {
  const match = urlOrPath.match(/\/verifications\/(.+)$/);
  if (match) return match[1];
  if (!urlOrPath.startsWith('http')) return urlOrPath;
  return null;
}

function NoPatientLinked({ email }: { email: string }) {
  return (
    <main className="min-h-screen bg-surface flex items-center justify-center px-6">
      <div className="bg-white rounded-4xl border border-outline p-10 max-w-md w-full space-y-5">
        <div className="text-center space-y-2">
          <div className="text-5xl">🔗</div>
          <h1 className="text-2xl font-extrabold text-ink">
            Link your person
          </h1>
          <p className="text-ink/70 text-sm">
            Signed in as <strong>{email}</strong>. Paste the link code
            from their MedBuddy Profile tab.
          </p>
        </div>
        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-3 text-xs text-amber-900 leading-relaxed">
          <strong>Can&apos;t follow your own account.</strong> The two
          accounts need separate email addresses. They sign up on the mobile
          app first, then tap the copy icon on their Profile tab to get the
          link code.
        </div>
        <LinkPatientForm />
        <form action="/api/signout" method="post">
          <button className="w-full text-sm text-ink/60 hover:text-ink">
            Sign out
          </button>
        </form>
      </div>
    </main>
  );
}
