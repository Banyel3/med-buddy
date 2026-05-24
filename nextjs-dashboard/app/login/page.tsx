'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const supabase = supabaseBrowser();
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    setBusy(false);
    if (error) setError(error.message);
    else router.push('/dashboard');
  }

  return (
    <main className="min-h-screen bg-coral-gradient flex items-center justify-center px-6">
      <form
        onSubmit={onSubmit}
        className="bg-white rounded-4xl shadow-2xl max-w-md w-full p-10 space-y-5"
      >
        <div>
          <h1 className="text-2xl font-extrabold text-ink">Welcome back</h1>
          <p className="text-ink/70 text-sm">Monitor MedBuddy adherence.</p>
        </div>
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
          className="w-full px-4 py-3 rounded-2xl bg-surface-container border border-outline focus:border-primary focus:outline-none"
        />
        {error && (
          <p className="text-sm text-danger">{error}</p>
        )}
        <button
          type="submit"
          disabled={busy}
          className="w-full bg-coral-gradient text-white font-semibold py-3 rounded-full shadow-lg disabled:opacity-50"
        >
          {busy ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </main>
  );
}
