'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabaseBrowser } from '@/lib/supabase/client';

/**
 * Subscribes to Supabase Realtime changes on compliance_logs and
 * triggers a Next.js router.refresh() so server components re-fetch.
 */
export default function RealtimeBridge({ patientId }: { patientId: string }) {
  const router = useRouter();

  useEffect(() => {
    const supabase = supabaseBrowser();
    const channel = supabase
      .channel(`monitor:${patientId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'compliance_logs',
          filter: `user_id=eq.${patientId}`,
        },
        () => router.refresh(),
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'streaks',
          filter: `user_id=eq.${patientId}`,
        },
        () => router.refresh(),
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [patientId, router]);

  return null;
}
