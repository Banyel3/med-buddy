# MedBuddy — Dev Testing Recipes

End-to-end recipes for exercising the Supabase REST API, Edge Functions, Postgres triggers, and the Next.js dashboard API while developing. Optimised for `curl` + `psql` so you can drive the system without touching the mobile app or browser.

> **Never commit real keys.** All secrets here are referenced by env var. Source them from `.env`, `nextjs-dashboard/.env.local`, or your local shell. The `WEBHOOK_SECRET` is in `/tmp/medbuddy-webhook-secret.txt` (chmod 600) until you move it to a password manager.

---

## 0. Environment

Source these once per shell session. Adjust paths if your repo lives elsewhere.

```bash
export PROJECT_ROOT="/Users/ban/dev/projects/med-buddy"
export SUPABASE_URL="https://dsvbnmleqzjdjpotacmt.supabase.co"
export SUPABASE_DB_HOST="db.dsvbnmleqzjdjpotacmt.supabase.co"
export SUPABASE_DB_USER="postgres"
export SUPABASE_DB_NAME="postgres"

# Read keys from .env files (don't echo these)
export SUPABASE_ANON_KEY=$(grep '^SUPABASE_ANON_KEY=' "$PROJECT_ROOT/.env" | cut -d= -f2-)
export SUPABASE_SERVICE_ROLE_KEY=$(grep '^SUPABASE_SERVICE_ROLE_KEY=' "$PROJECT_ROOT/nextjs-dashboard/.env.local" | cut -d= -f2-)
export PGPASSWORD=$(grep -oE 'postgres:[^@]+@' "$PROJECT_ROOT/.env" 2>/dev/null | sed 's/postgres://;s/@//')
# If PGPASSWORD is empty, paste your DB password manually:
# export PGPASSWORD='your-db-password-here'

export WEBHOOK_SECRET=$(grep WEBHOOK_SECRET /tmp/medbuddy-webhook-secret.txt 2>/dev/null | cut -d= -f2)

# Sanity check (lengths only, no values)
echo "anon: ${#SUPABASE_ANON_KEY}, service: ${#SUPABASE_SERVICE_ROLE_KEY}, webhook: ${#WEBHOOK_SECRET}, db: ${#PGPASSWORD}"
# Expect: anon: ~200+, service: ~200+, webhook: 64, db: ~16
```

A helper for psql:

```bash
psql_db() {
  psql -h "$SUPABASE_DB_HOST" -p 5432 -U "$SUPABASE_DB_USER" -d "$SUPABASE_DB_NAME" "$@"
}
```

---

## 1. Inspect current state

Quick "what's in the system" snapshot:

```bash
psql_db -c "
select au.id, au.email, pu.role, pu.name, au.created_at::date
from auth.users au left join public.users pu on pu.id=au.id
order by au.created_at;"
```

```bash
psql_db -c "
select id, user_id, date, status, face_confidence, pill_confidence
from public.compliance_logs order by created_at desc limit 20;"
```

```bash
psql_db -c "select * from public.streaks;"
```

```bash
psql_db -c "select * from public.monitor_links;"
```

---

## 2. Auth — get a patient JWT

You need a JWT (access token) to hit the REST API as a real user with RLS enforced. Use the password you set when signing up.

```bash
TOKEN_JSON=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"van@gmail.com","password":"YOUR-PATIENT-PASSWORD"}')

export PATIENT_JWT=$(echo "$TOKEN_JSON" | jq -r .access_token)
export PATIENT_ID=$(echo "$TOKEN_JSON" | jq -r .user.id)

echo "patient: $PATIENT_ID, jwt len: ${#PATIENT_JWT}"
```

Same for the monitor:

```bash
TOKEN_JSON=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"john@gmail.com","password":"YOUR-MONITOR-PASSWORD"}')

export MONITOR_JWT=$(echo "$TOKEN_JSON" | jq -r .access_token)
export MONITOR_ID=$(echo "$TOKEN_JSON" | jq -r .user.id)
```

JWTs expire in 1 hour by default. Re-run when stale (401 responses).

---

## 3. Mock a medication

> **RLS requires `user_id`** in the insert payload. The `meds_owner_write` policy
> checks `user_id = auth.uid()` on both `using` and `with check`. Omit it and you
> get `42501 new row violates row-level security policy`. Always pass `user_id`
> explicitly when inserting via REST.

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/medications" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\":\"$PATIENT_ID\",
    \"name\":\"Test Pill\",
    \"schedule_time\":\"08:00:00\",
    \"notes\":\"dev mock\"
  }" | jq
```

Save the returned `id` (jq one-liner):

```bash
export MED_ID=$(curl -s -X POST "$SUPABASE_URL/rest/v1/medications" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{\"user_id\":\"$PATIENT_ID\",\"name\":\"Vitamin D\",\"schedule_time\":\"09:00:00\",\"notes\":\"\"}" \
  | jq -r '.[0].id')
echo "MED_ID=$MED_ID"
```

---

## 4. Mock compliance logs — the core of dev testing

Three patterns: insert a verified row, insert a pending row, transition pending → missed (fires miss-alert).

### 4a. Verified dose (bumps streak)

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/compliance_logs" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"medication_id\":\"$MED_ID\",
    \"user_id\":\"$PATIENT_ID\",
    \"date\":\"$(date -u +%Y-%m-%d)\",
    \"status\":\"verified\",
    \"face_confidence\":0.92,
    \"pill_confidence\":0.81,
    \"verified_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }" | jq
```

Verify the streak trigger fired:

```bash
psql_db -c "select * from public.streaks where user_id='$PATIENT_ID';"
```

### 4b. Backfill a 7-day streak (for dashboard testing)

```bash
psql_db <<SQL
insert into public.compliance_logs (medication_id, user_id, date, status,
                                    face_confidence, pill_confidence, verified_at)
select '$MED_ID', '$PATIENT_ID', (current_date - n)::date, 'verified',
       0.9, 0.8, (now() - (n||' days')::interval)
from generate_series(0, 6) n
on conflict do nothing;

select date, status from public.compliance_logs
where user_id='$PATIENT_ID' order by date desc limit 10;
SQL
```

### 4c. Pending dose (today, not yet verified)

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/compliance_logs" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"medication_id\":\"$MED_ID\",
    \"user_id\":\"$PATIENT_ID\",
    \"date\":\"$(date -u +%Y-%m-%d)\",
    \"status\":\"pending\"
  }"
```

### 4d. Transition pending → missed (fires the miss-alert trigger)

```bash
LOG_ID=$(psql_db -tAc "
select id from public.compliance_logs
where user_id='$PATIENT_ID' and status='pending'
order by created_at desc limit 1;")

psql_db -c "update public.compliance_logs set status='missed' where id='$LOG_ID';"
```

The DB trigger `compliance_logs_miss_alert` POSTs to the miss-alert Edge Function. Check the result:

```bash
psql_db -c "
select id, status_code, content::text, created
from net._http_response order by created desc limit 3;"
```

Expect `200` (or `200 no monitors` / `200 no tokens` if no monitor links exist).

---

## 5. Edge Functions — invoke directly

### miss-alert (manual fire)

```bash
RECORD_ID=$(psql_db -tAc "select id from public.compliance_logs where status='missed' limit 1;")

curl -s -X POST "$SUPABASE_URL/functions/v1/miss-alert" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: $WEBHOOK_SECRET" \
  -d "{\"record\":{\"id\":\"$RECORD_ID\"}}"
```

Expected outcomes:
- `ok` — push fan-out attempted (will fail silently if FCM_SERVER_KEY unset)
- `no monitors` — no monitor_links row for this patient
- `no tokens` — monitor exists but no device_tokens row
- `FCM_SERVER_KEY not configured` — set it via `supabase secrets set` if you wire FCM

### daily-rollover (manual fire)

```bash
curl -s -X POST "$SUPABASE_URL/functions/v1/daily-rollover" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: $WEBHOOK_SECRET" | jq
```

Expected:
```json
{ "ok": true, "missed_marked_for_dates_before": "YYYY-MM-DD", "streaks_reset": 0 }
```

### storage-ttl (manual fire)

```bash
curl -s -X POST "$SUPABASE_URL/functions/v1/storage-ttl" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: $WEBHOOK_SECRET" | jq
```

Expected:
```json
{ "ok": true, "retention_days": 30, "deleted": 0 }
```

### Negative tests (security smoke)

```bash
# No header → 401
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$SUPABASE_URL/functions/v1/miss-alert" -d '{}'
# Wrong secret → 401
curl -s -o /dev/null -w "%{http_code}\n" -X POST "$SUPABASE_URL/functions/v1/miss-alert" \
  -H "x-webhook-secret: wrong" -d '{}'
```

Both should print `401`.

---

## 6. Storage — upload + signed URL

Pre-flight: bucket `verifications` is private, RLS-protected.

### Upload a test photo

```bash
# Create a 1x1 PNG locally (any small file works)
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\rIDATx\x9cc\xfc\xff\xff?\x00\x05\xfe\x02\xfe\xa3X\x90c\x00\x00\x00\x00IEND\xaeB`\x82' > /tmp/test.png

PATH_IN_BUCKET="$PATIENT_ID/$(date -u +%Y%m%dT%H%M%S)-test.png"

curl -s -X POST "$SUPABASE_URL/storage/v1/object/verifications/$PATH_IN_BUCKET" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: image/png" \
  --data-binary @/tmp/test.png | jq
```

### Get a signed URL (5-minute expiry)

```bash
curl -s -X POST "$SUPABASE_URL/storage/v1/object/sign/verifications/$PATH_IN_BUCKET" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -d '{"expiresIn": 300}' | jq
```

---

## 7. Dashboard API — local Next.js routes

Make sure `npm run dev` is running (`http://localhost:3000`).

### Sign in as monitor (browser cookie flow — use the UI). For non-browser testing:

```bash
# Sign in via Supabase REST (same as section 2) — gets you a JWT not a cookie.
# The dashboard's /api/link route reads cookies, so testing it via curl needs
# to send the Supabase auth cookie. Easiest path: use the browser.
```

### Link a patient (run from a logged-in browser console)

```js
await fetch('/api/link', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ code: 'MB-6A0420' }) // or full UUID
}).then(r => r.json())
```

Expected: `{ ok: true }` → reload, dashboard shows linked patient.

---

## 8. Realtime — quick sanity

Patient inserts a `compliance_logs` row → monitor dashboard ought to update without refresh. Test by:

1. Open dashboard in browser as monitor (linked to patient).
2. Run §4a insert from the terminal.
3. Dashboard should re-render within 1-2s via `RealtimeBridge`.

If it doesn't, check the browser console for `supabase.channel` errors and confirm Realtime is enabled in Supabase Dashboard → Database → Replication.

---

## 9. Reset / cleanup test data

Nuke compliance + streak test data for a user:

```bash
psql_db <<SQL
delete from public.compliance_logs where user_id='$PATIENT_ID';
delete from public.streaks where user_id='$PATIENT_ID';
delete from public.medications where user_id='$PATIENT_ID';
select 'logs:', count(*) from public.compliance_logs where user_id='$PATIENT_ID'
union all select 'streaks:', count(*) from public.streaks where user_id='$PATIENT_ID'
union all select 'meds:', count(*) from public.medications where user_id='$PATIENT_ID';
SQL
```

Wipe ALL test data (careful — this is everyone):

```bash
psql_db -c "truncate public.compliance_logs, public.streaks, public.medications restart identity cascade;"
```

Wipe storage:

```bash
# List + delete a single user's folder
curl -s -X DELETE "$SUPABASE_URL/storage/v1/object/verifications/$PATH_IN_BUCKET" \
  -H "Authorization: Bearer $PATIENT_JWT"
```

---

## 10. Smoke test recipe (one-shot end-to-end)

Paste this whole block to exercise the whole adherence loop on a fresh patient:

```bash
# Assumes env from §0 + JWTs from §2 + MED_ID from §3
TODAY=$(date -u +%Y-%m-%d)

# 1. Insert pending today
curl -s -X POST "$SUPABASE_URL/rest/v1/compliance_logs" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "{\"medication_id\":\"$MED_ID\",\"user_id\":\"$PATIENT_ID\",\"date\":\"$TODAY\",\"status\":\"pending\"}" | jq -r .[0].id

# 2. Mark as verified — bumps streak via trigger
curl -s -X PATCH "$SUPABASE_URL/rest/v1/compliance_logs?date=eq.$TODAY&user_id=eq.$PATIENT_ID" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"verified\",\"face_confidence\":0.95,\"pill_confidence\":0.84,\"verified_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

# 3. Confirm streak = 1
psql_db -c "select current_streak, longest_streak, last_verified_date from public.streaks where user_id='$PATIENT_ID';"

# 4. Run daily-rollover (no-op on today's verified row; should not flip it)
curl -s -X POST "$SUPABASE_URL/functions/v1/daily-rollover" \
  -H "Content-Type: application/json" -H "x-webhook-secret: $WEBHOOK_SECRET" | jq

# 5. Simulate yesterday-missed by inserting a pending row for yesterday
YESTERDAY=$(date -u -v-1d +%Y-%m-%d 2>/dev/null || date -u -d 'yesterday' +%Y-%m-%d)
curl -s -X POST "$SUPABASE_URL/rest/v1/compliance_logs" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $PATIENT_JWT" \
  -H "Content-Type: application/json" \
  -d "{\"medication_id\":\"$MED_ID\",\"user_id\":\"$PATIENT_ID\",\"date\":\"$YESTERDAY\",\"status\":\"pending\"}"

# 6. Run daily-rollover again — should flip yesterday's pending to missed, firing miss-alert
curl -s -X POST "$SUPABASE_URL/functions/v1/daily-rollover" \
  -H "Content-Type: application/json" -H "x-webhook-secret: $WEBHOOK_SECRET" | jq

# 7. Check the trigger-fired http request landed
psql_db -c "select status_code, content::text from net._http_response order by created desc limit 1;"
```

---

## 11. Lock mode (hard vs. soft)

Switching modes — three layers, highest wins:

```
1. Build flag         flutter run --dart-define=MEDBUDDY_LOCK_MODE=soft
2. .env (mobile root) MEDBUDDY_LOCK_MODE=hard
3. User toggle        Profile → Lock style (only enabled when 1 and 2 unset)
```

Dev workflow: pin via build flag on your dev branch, ship prod builds with
`MEDBUDDY_LOCK_MODE` unset so end users can change it themselves.

```bash
# Force soft for QA builds
flutter run -d emulator-5554 --dart-define=MEDBUDDY_LOCK_MODE=soft

# Force hard for production smoke
flutter build apk --release --dart-define=MEDBUDDY_LOCK_MODE=hard

# Per-machine override without rebuild
echo 'MEDBUDDY_LOCK_MODE=soft' >> .env
```

When env-pinned, the Profile Lock-style SegmentedButton disables with the
hint "Pinned by build flag / .env".

Lock alarm test (works on physical device only — emulator can't render
TYPE_ACCESSIBILITY_OVERLAY reliably):

```bash
# 1. On device: Settings → Accessibility → MedBuddy → On
# 2. Settings → Apps → MedBuddy → Display over other apps → Allow
# 3. Settings → Apps → MedBuddy → Alarms & reminders → Allow (A12+)
# 4. In app: add a med scheduled 2 minutes in the future
# 5. Background the app. Wait 32 minutes (med_time + 30).
# 6. Overlay should auto-appear, BACK / HOME bounce back.
# 7. In SOFT mode: tap "Skip for now (tap 5×)" five times → overlay clears.
# 8. In HARD mode: only completing verification clears it.
```

Recovery if lock gets stuck (no verification possible):

| Path | Steps |
|---|---|
| Settings | Notification shade → Settings → Accessibility → MedBuddy → Off |
| ADB force-stop | `adb shell am force-stop com.medbuddy.medbuddy` |
| ADB uninstall | `adb shell pm uninstall com.medbuddy.medbuddy` |
| Safe Mode | Power button → long-press "Power Off" → Reboot to safe mode |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `401 invalid webhook secret` from any Edge Function | `WEBHOOK_SECRET` env on Supabase doesn't match what you sent | Re-set via `supabase secrets set --env-file /tmp/medbuddy-secrets.env` then redeploy the function |
| `403 new row violates row-level security policy` on REST insert | Your JWT user_id doesn't match the `user_id` you're inserting | Use the JWT's actual user.id (echo `$PATIENT_ID`) |
| Trigger `compliance_logs_miss_alert` not firing | Looking at `auth.users` instead of `public.users.id`; or status was already 'missed' before update | Check `select * from net._http_response order by created desc limit 5;` — empty = no HTTP fired |
| `bump_streak` not incrementing | Inserting row with `status != 'verified'`, or same-day row already counted | Verify status, check `last_verified_date` in streaks row |
| Dashboard live update missing | Realtime disabled, or `RealtimeBridge` not mounted | Inspect Supabase Dashboard → Database → Replication: `compliance_logs` should be enabled |
