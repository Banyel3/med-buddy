import Link from 'next/link';
import { redirect } from 'next/navigation';
import { supabaseServer } from '@/lib/supabase/server';

export default async function Home() {
  const supabase = supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect('/dashboard');

  return (
    <main className="min-h-screen bg-coral-gradient flex items-center justify-center px-6">
      <div className="bg-white/95 backdrop-blur rounded-4xl shadow-2xl max-w-md w-full p-10">
        <div className="text-5xl mb-3">💊</div>
        <h1 className="text-3xl font-extrabold text-ink mb-2">
          MedBuddy Monitor
        </h1>
        <p className="text-ink/70 mb-8">
          Track adherence in real time. Sign in to view your linked
          patient&apos;s streak and verification log.
        </p>
        <Link
          href="/login"
          className="block w-full text-center bg-coral-gradient text-white font-semibold py-3 rounded-full shadow-lg"
        >
          Sign in
        </Link>
      </div>
    </main>
  );
}
