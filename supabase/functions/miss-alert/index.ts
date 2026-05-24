// Supabase Edge Function: miss-alert
// ---------------------------------------------------------------
// Triggered via Supabase Database Webhook when a compliance_logs
// row's status transitions to "missed". For each verified missed
// row, looks up every monitor_link.monitor_id and posts an FCM push.
//
// Security model
// --------------
// - The function uses SUPABASE_SERVICE_ROLE_KEY (RLS bypassed),
//   so the request MUST be authenticated before any DB read.
// - Authentication: shared-secret header `x-webhook-secret` (set
//   on the Database Webhook config in the Supabase dashboard, and
//   stored in the function env as WEBHOOK_SECRET). The secret is
//   compared in constant time to defeat timing oracles.
// - Payload as pointer only: we never trust body.record.user_id
//   or body.record.status. We re-select the row from compliance_logs
//   by `record.id` and use ITS user_id / status to authorize and
//   shape the push. This blocks payload spoofing even by a caller
//   who somehow obtained the shared secret.
//
// Deploy
// ------
//   # 1. Generate a strong secret (32+ chars):
//   #    openssl rand -hex 32
//   supabase secrets set WEBHOOK_SECRET=<that-value>
//   supabase secrets set FCM_SERVER_KEY=<firebase-server-key>
//   supabase functions deploy miss-alert
//
// Database Webhook config (Supabase dashboard → Database → Webhooks)
// ------------------------------------------------------------------
//   Table:     compliance_logs
//   Events:    UPDATE
//   Condition: new.status = 'missed' AND old.status != 'missed'
//   URL:       https://<project-ref>.functions.supabase.co/miss-alert
//   Headers:   x-webhook-secret: <same value as WEBHOOK_SECRET>
// ---------------------------------------------------------------

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';
import { checkWebhookSecret } from '../_shared/security.ts';

interface MissedPayload {
  record?: { id?: string };
}

/// Pure predicate — `miss-alert` only fans out FCM when the
/// authoritative DB row's status is exactly `'missed'`. Exported so
/// `_tests/miss_alert_test.ts` exercises the actual production logic.
export const shouldFireMissAlert = (row: { status: string }): boolean =>
  row.status === 'missed';

Deno.serve(async (req) => {
  // --- Authn: shared-secret header (constant-time) ---
  const auth = checkWebhookSecret(req, Deno.env.get('WEBHOOK_SECRET'));
  if (!auth.ok) {
    return new Response(`unauthorized: ${auth.reason}`, { status: 401 });
  }

  try {
    const body: MissedPayload = await req.json().catch(() => ({}));
    const recordId = body.record?.id;
    if (!recordId || typeof recordId !== 'string') {
      return new Response('bad request: record.id required', { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // --- Authz: re-fetch by id, trust DB state only ---
    const { data: log, error: logErr } = await supabase
      .from('compliance_logs')
      .select('id, user_id, date, status')
      .eq('id', recordId)
      .maybeSingle();
    if (logErr) {
      console.error('miss-alert: log fetch failed', logErr);
      return new Response('db error', { status: 500 });
    }
    if (!log) {
      return new Response('not found', { status: 404 });
    }
    if (!shouldFireMissAlert(log)) {
      // Webhook fired in a race / row got fixed. No-op.
      return new Response('ignored: status not missed', { status: 200 });
    }

    const userId: string = log.user_id;

    // Independent reads — fan out in parallel.
    const [patientRes, linksRes] = await Promise.all([
      supabase.from('users').select('name').eq('id', userId).maybeSingle(),
      supabase
        .from('monitor_links')
        .select('monitor_id')
        .eq('patient_id', userId),
    ]);
    const patient = patientRes.data;
    const links = linksRes.data;

    if (!links || links.length === 0) {
      return new Response('no monitors', { status: 200 });
    }

    const monitorIds = links.map((l) => l.monitor_id);
    const { data: tokens } = await supabase
      .from('device_tokens')
      .select('token, platform')
      .in('user_id', monitorIds);

    if (!tokens || tokens.length === 0) {
      return new Response('no tokens', { status: 200 });
    }

    const fcmKey = Deno.env.get('FCM_SERVER_KEY');
    if (!fcmKey) {
      return new Response('FCM_SERVER_KEY not configured', { status: 500 });
    }

    const title = `${patient?.name ?? 'Your patient'} missed a dose`;
    const message = `Date: ${log.date}. Check the dashboard.`;

    await Promise.all(
      tokens.map((t) =>
        fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${fcmKey}`,
          },
          body: JSON.stringify({
            to: t.token,
            notification: { title, body: message },
            data: { logId: log.id, kind: 'miss-alert' },
          }),
        }),
      ),
    );

    return new Response('ok', { status: 200 });
  } catch (e) {
    console.error('miss-alert error', e);
    return new Response('error', { status: 500 });
  }
});
