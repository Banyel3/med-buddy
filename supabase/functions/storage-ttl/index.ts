// Supabase Edge Function: storage-ttl
// ---------------------------------------------------------------
// Purges verification photos older than 30 days from the
// `verifications` bucket. Runs daily via cron.
//
// Schedule:
//   `30 0 * * *` (any timezone — UTC fine) → invokes this URL.
// ---------------------------------------------------------------

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { isPhotoExpired } from '../_shared/streak_math.ts';

const RETENTION_DAYS = 30;

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const now = new Date();

  // List all top-level folders (one per user).
  const { data: folders, error: listErr } = await supabase.storage
    .from('verifications')
    .list('', { limit: 1000 });

  if (listErr) {
    console.error('list folders failed', listErr);
    return new Response('list err', { status: 500 });
  }

  let deleted = 0;

  for (const folder of folders ?? []) {
    if (!folder.name) continue;
    const { data: files } = await supabase.storage
      .from('verifications')
      .list(folder.name, { limit: 1000 });
    if (!files) continue;

    const expired = files
      .filter((f) =>
        isPhotoExpired(
          f.created_at ? new Date(f.created_at) : null,
          RETENTION_DAYS,
          now,
        ),
      )
      .map((f) => `${folder.name}/${f.name}`);

    if (expired.length > 0) {
      const { error: rmErr } = await supabase.storage
        .from('verifications')
        .remove(expired);
      if (rmErr) {
        console.error('remove failed', folder.name, rmErr);
      } else {
        deleted += expired.length;
      }
    }
  }

  return new Response(
    JSON.stringify({
      ok: true,
      retention_days: RETENTION_DAYS,
      deleted,
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
