// Supabase Edge Function: daily-rollover
// ---------------------------------------------------------------
// Runs once per day per timezone (cron). Two responsibilities:
//   1. Mark every `pending` compliance_log row whose date < today
//      as `missed` (triggers the miss-alert webhook downstream).
//   2. Reset streaks.current_streak to 0 for any user whose
//      last_verified_date < today - 1 day (broke the streak).
//
// Schedule via Supabase Dashboard → Database → Functions → Cron:
//   `0 0 * * *` Asia/Manila → invokes this function URL.
// ---------------------------------------------------------------

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { checkWebhookSecret } from '../_shared/security.ts';
import {
  nextLongestStreak,
  shouldResetStreak,
} from '../_shared/streak_math.ts';

Deno.serve(async (req) => {
  const auth = checkWebhookSecret(req, Deno.env.get('WEBHOOK_SECRET'));
  if (!auth.ok) {
    return new Response(`unauthorized: ${auth.reason}`, { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const today = new Date().toISOString().slice(0, 10);

  // 1) Mark expired pending logs as missed.
  const { error: missErr } = await supabase
    .from('compliance_logs')
    .update({ status: 'missed' })
    .eq('status', 'pending')
    .lt('date', today);
  if (missErr) console.error('miss-mark failed', missErr);

  // 2) Reset broken streaks.
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const ydKey = yesterday.toISOString().slice(0, 10);

  const { data: stale } = await supabase
    .from('streaks')
    .select('id, user_id, last_verified_date, longest_streak, current_streak')
    .lt('last_verified_date', ydKey);

  if (stale && stale.length > 0) {
    const now = new Date();
    await Promise.all(
      stale
        .filter((s) =>
          shouldResetStreak(
            s.last_verified_date ? new Date(s.last_verified_date) : null,
            now,
          ),
        )
        .map((s) =>
          supabase
            .from('streaks')
            .update({
              current_streak: 0,
              longest_streak: nextLongestStreak(
                s.current_streak ?? 0,
                s.longest_streak ?? 0,
              ),
              updated_at: now.toISOString(),
            })
            .eq('id', s.id),
        ),
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      missed_marked_for_dates_before: today,
      streaks_reset: stale?.length ?? 0,
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
