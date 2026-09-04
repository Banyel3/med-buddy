'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

export default function LinkPatientForm() {
  const router = useRouter();
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch('/api/link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: code.trim() }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(json?.error ?? `Link failed (${res.status})`);
        setBusy(false);
        return;
      }
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Network error');
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-3">
      <input
        value={code}
        onChange={(e) => setCode(e.target.value)}
        placeholder="MB-XXXXXX  or  full UUID"
        required
        autoComplete="off"
        spellCheck={false}
        className="w-full px-4 py-3 rounded-2xl bg-surface-container border border-outline font-mono text-sm focus:border-primary focus:outline-none"
      />
      {error && (
        <p className="text-sm text-danger" role="alert">
          {error}
        </p>
      )}
      <button
        type="submit"
        disabled={busy || code.trim().length === 0}
        className="w-full bg-coral-gradient text-white font-semibold py-3 rounded-full shadow-lg disabled:opacity-50"
      >
        {busy ? 'Linking…' : 'Link account'}
      </button>
    </form>
  );
}
