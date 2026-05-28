'use client';

import { Suspense, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <main className="min-h-screen bg-coral-gradient flex items-center justify-center px-6">
          <div className="bg-white rounded-4xl shadow-2xl max-w-md w-full p-10">
            <p className="text-ink/70 text-sm">Loading…</p>
          </div>
        </main>
      }
    >
      <LoginForm />
    </Suspense>
  );
}

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [mode, setMode] = useState<'signin' | 'signup'>(
    searchParams.get('mode') === 'signup' ? 'signup' : 'signin',
  );
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setInfo(null);
    const supabase = supabaseBrowser();
    if (mode === 'signin') {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      setBusy(false);
      if (error) setError(error.message);
      else router.push('/dashboard');
    } else {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name: name.trim() || email.split('@')[0], role: 'monitor' },
        },
      });
      setBusy(false);
      if (error) {
        setError(error.message);
      } else if (data.session) {
        router.push('/dashboard');
      } else {
        setInfo('Check your inbox to confirm your email, then sign in.');
        setMode('signin');
      }
    }
  }

  const isSignup = mode === 'signup';

  return (
    <main className="min-h-screen bg-coral-gradient flex items-center justify-center px-6">
      <form
        onSubmit={onSubmit}
        className="bg-white rounded-4xl shadow-2xl max-w-md w-full p-10 space-y-5"
      >
        <div>
          <h1 className="text-2xl font-extrabold text-ink">
            {isSignup ? 'Create a monitor account' : 'Welcome back'}
          </h1>
          <p className="text-ink/70 text-sm">Monitor MedBuddy adherence.</p>
        </div>
        {isSignup && (
          <input
            type="text"
            placeholder="Your name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-4 py-3 rounded-2xl bg-surface-container border border-outline focus:border-primary focus:outline-none"
          />
        )}
        <input
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          className="w-full px-4 py-3 rounded-2xl bg-surface-container border border-outline focus:border-primary focus:outline-none"
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          minLength={6}
          className="w-full px-4 py-3 rounded-2xl bg-surface-container border border-outline focus:border-primary focus:outline-none"
        />
        {error && <p className="text-sm text-danger">{error}</p>}
        {info && <p className="text-sm text-ink/70">{info}</p>}
        <button
          type="submit"
          disabled={busy}
          className="w-full bg-coral-gradient text-white font-semibold py-3 rounded-full shadow-lg disabled:opacity-50"
        >
          {busy
            ? isSignup
              ? 'Creating…'
              : 'Signing in…'
            : isSignup
              ? 'Create account'
              : 'Sign in'}
        </button>
        <div className="flex items-center gap-2 text-xs text-ink/50">
          <span className="h-px flex-1 bg-outline" />
          <span>or</span>
          <span className="h-px flex-1 bg-outline" />
        </div>
        <button
          type="button"
          onClick={() => {
            setMode(isSignup ? 'signin' : 'signup');
            setError(null);
            setInfo(null);
          }}
          className="w-full border-2 border-primary text-primary font-semibold py-3 rounded-full hover:bg-primary/5"
        >
          {isSignup ? 'Sign in instead' : 'Create monitor account'}
        </button>
        <p className="text-xs text-ink/60 text-center leading-relaxed">
          Heads up: patients sign up on the <strong>mobile app</strong>.
          You can&apos;t monitor your own account — the patient and
          monitor must be separate email accounts.
        </p>
      </form>
    </main>
  );
}
