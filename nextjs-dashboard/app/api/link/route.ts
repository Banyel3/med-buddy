import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { supabaseServer } from '@/lib/supabase/server';

const SHORT_OR_FULL =
  /^(MB-)?([0-9a-f]{6}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/i;

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  const rawCode = (body.code ?? '').toString().trim();

  if (!SHORT_OR_FULL.test(rawCode)) {
    return NextResponse.json(
      {
        error:
          "Paste the link code from the patient's mobile Profile tab — looks like MB-XXXXXX.",
      },
      { status: 400 },
    );
  }

  const supabase = supabaseServer();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: 'Not signed in.' }, { status: 401 });
  }

  const admin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );

  const { data: matches, error: rpcErr } = await admin.rpc(
    'find_patient_by_link_code',
    { p_code: rawCode },
  );
  if (rpcErr) {
    return NextResponse.json({ error: rpcErr.message }, { status: 500 });
  }
  if (!matches || matches.length === 0) {
    return NextResponse.json(
      {
        error:
          'No patient with that code. Make sure they signed up on the mobile app and copied the code from Profile.',
      },
      { status: 404 },
    );
  }
  if (matches.length > 1) {
    return NextResponse.json(
      {
        error:
          'That short code matches more than one account. Tap the copy icon in the mobile app to paste the full UUID instead.',
      },
      { status: 409 },
    );
  }

  const patient = matches[0] as { id: string; role: string };
  if (patient.id === user.id) {
    return NextResponse.json(
      {
        error:
          'That is your own account code. Sign up a separate account on the mobile app as the patient.',
      },
      { status: 400 },
    );
  }
  if (patient.role !== 'patient') {
    return NextResponse.json(
      { error: 'That account is registered as a monitor, not a patient.' },
      { status: 400 },
    );
  }

  const { error: insertErr } = await admin
    .from('monitor_links')
    .insert({ patient_id: patient.id, monitor_id: user.id });
  if (insertErr && !insertErr.message.toLowerCase().includes('duplicate')) {
    return NextResponse.json({ error: insertErr.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
