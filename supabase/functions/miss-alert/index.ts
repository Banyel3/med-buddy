// Supabase Edge Function: miss-alert
// ---------------------------------------------------------------
// Triggered (a) via Database webhook when a compliance_logs row's
// status transitions to "missed", or (b) by cron at end-of-day to
// mark unverified pending rows as missed.
//
// For each missed row, looks up every monitor_link.monitor_id and
// posts a push notification via FCM (Android / iOS).
//
// Deploy:
//   supabase functions deploy miss-alert
// Set secrets:
//   supabase secrets set FCM_SERVER_KEY=...
//
// Database webhook config (in Supabase dashboard):
//   Table: compliance_logs
//   Events: UPDATE
//   Condition: new.status = 'missed' AND old.status != 'missed'
//   URL: https://<project-ref>.functions.supabase.co/miss-alert
// ---------------------------------------------------------------

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

interface MissedPayload {
  record: {
    id: string;
    user_id: string;
    date: string;
    status: string;
  };
}

Deno.serve(async (req) => {
  try {
    const body: MissedPayload = await req.json();
    const log = body.record;
    if (log.status !== 'missed') {
      return new Response('ignored', { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: patient } = await supabase
      .from('users')
      .select('name')
      .eq('id', log.user_id)
      .maybeSingle();

    const { data: links } = await supabase
      .from('monitor_links')
      .select('monitor_id')
      .eq('patient_id', log.user_id);

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
