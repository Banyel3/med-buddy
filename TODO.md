# MedBuddy — TODO

Living checklist. Tick as done. Order = do top → bottom.

---

## Phase status

| Phase | Code complete | Manual setup left | Notes |
|-------|---------------|-------------------|-------|
| 1 — Foundation | ✅ | env + Supabase | analyze clean |
| 2 — Verification | ✅ | drop tflite + camera perms | YOLOv8 decoder ready |
| 3 — Android lock | ✅ | enable accessibility on device | real-device test only |
| 4 — Dashboard | ✅ | npm install + Vercel + edge fns | schema.sql ready |
| 5 — Polish | ✅ code-side | external assets (icon, splash, FCM, Sentry DSN) | iOS modal fallback live |
| 6 — PH market | ⏳ | future | future |
| Sec — miss-alert hardening | ✅ code-side | rotate WEBHOOK_SECRET + add header to DB Webhook | constant-time + DB re-fetch |

---

## 0. One-time machine setup

- [ ] `flutter doctor -v` — confirm Android toolchain green
- [ ] Android Studio → Device Manager → create AVD with **ARM image** (API 34+), NOT x86 (M4 chip)
- [ ] Plug in real Android device (Samsung A / Redmi / realme) → enable USB debugging → `flutter devices` shows it
- [ ] Java 17 ≤ JDK < 25 — current Java may conflict with Gradle 8.14 warning. Fix: `flutter config --jdk-dir=<path-to-jdk17>` if Gradle errors
- [ ] `node -v` ≥ 18 + `npm -v` ≥ 9 (for Next.js dashboard)
- [ ] Install Supabase CLI: `brew install supabase/tap/supabase`
- [ ] Install Vercel CLI: `npm i -g vercel`

## 1. Supabase project (blocks everything backend)

- [ ] Create project at https://supabase.com
- [ ] Copy `Project URL` + `anon public` key → paste into `.env` (root) AND `nextjs-dashboard/.env.local`
- [ ] Copy `service_role` key into `nextjs-dashboard/.env.local` as `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Run `supabase/schema.sql` in Supabase SQL editor (creates all 6 tables, enum types, streak trigger, RLS policies)
- [ ] Storage → create private bucket `verifications` → uncomment + run the two `storage.objects` policies at the bottom of `schema.sql`
- [ ] Auth → enable Email provider; toggle off email confirmation for dev
- [ ] After first sign-up: manually insert a `users` row (`id = auth.users.id`, name, role) — or wire a trigger later

## 2. Phase 1 smoke test (UI shell)

- [ ] `flutter pub get`
- [ ] `flutter analyze` → No issues found
- [ ] `flutter run` on ARM emulator — splash → login → onboarding (4 steps) → home
- [ ] Resize past 600dp → NavigationRail appears
- [ ] History tab → empty calendar renders
- [ ] Notifications: grant permission; verify 12:30 PHT reminder fires (system-clock test)

## 3. Phase 2 — Verification ✅ code done, manual:

- [ ] Clone `seblful/pills-detection` → grab `best.pt`
- [ ] `pip install ultralytics` → `python -c "from ultralytics import YOLO; YOLO('best.pt').export(format='tflite')"`
- [ ] Drop `pills_detection.tflite` into `assets/models/`
- [ ] Add seblful credit (CC BY 4.0) to in-app credits screen (TBD Phase 5)
- [ ] Real-device test: capture flow → MLKit face → TFLite pill → upload → log row in Supabase

## 4. Phase 3 — Android accessibility lock ✅ code done, manual:

- [ ] Real Android device (emulator unreliable for system overlays)
- [ ] After first install: Settings → Accessibility → MedBuddy → Enable
- [ ] Settings → Apps → MedBuddy → Display over other apps → Allow
- [ ] Smoke test: trigger `lock-activate` notification → overlay appears → BACK/HOME bounces back → verify dose → overlay clears
- [ ] Test on Samsung One UI (Knox quirks) + Xiaomi MIUI / realme UI (autostart restrictions)
- [ ] Confirm emergency dialer + Settings → Accessibility always pass through

## 5. Phase 4 — Next.js monitor dashboard ✅ code done, manual:

- [ ] `cd nextjs-dashboard && npm install` (already done if you ran it)
- [ ] `cp .env.local.example .env.local` → fill 3 keys
- [ ] `npm run dev` → http://localhost:3000 → sign in
- [ ] Manually insert a `monitor_links` row linking your monitor account to the patient account
- [ ] Confirm dashboard live-updates when patient verifies a dose (Supabase Realtime)
- [ ] Deploy: `vercel --prod` → set the 3 env vars in Vercel project settings
- [ ] `supabase functions deploy miss-alert`
- [ ] `supabase functions deploy daily-rollover`
- [ ] `supabase functions deploy storage-ttl`
- [ ] `supabase secrets set FCM_SERVER_KEY=...` (Firebase console → Project settings → Cloud Messaging → Server key)
- [ ] **Security:** `SECRET=$(openssl rand -hex 32) && supabase secrets set WEBHOOK_SECRET="$SECRET"` — then add HTTP header `x-webhook-secret: $SECRET` to the Database Webhook config (miss-alert returns 401 without it)
- [ ] Add Database Webhook in Supabase: table=compliance_logs, event=UPDATE, condition=`new.status='missed' AND old.status!='missed'`, URL=function URL, HTTP headers include `x-webhook-secret`
- [ ] Schedule `daily-rollover` via Supabase cron: `5 0 * * *` (00:05 Asia/Manila)
- [ ] Schedule `storage-ttl` via Supabase cron: `30 0 * * *` (UTC)
- [ ] Wire FCM device-token registration in mobile app (Phase 5 — see below)

---

## 5. Phase 5 — Polish

Code-side ✅ done:
- [x] Profile screen (sign-out, monitor link code, dark-mode toggle, credits link)
- [x] Dark mode (full Material 3 dark scheme + system / manual override)
- [x] Credits & licenses screen (seblful + ML Kit + fonts + SDK)
- [x] iOS modal fallback lock (LockGate wraps app; listens to `lockedNotifier`)
- [x] daily-rollover Edge Function (mark pending → missed + reset broken streaks)
- [x] storage-ttl Edge Function (auto-purge verification photos > 30 days)
- [x] Privacy policy page (`nextjs-dashboard/app/privacy/page.tsx`)
- [x] GitHub Actions CI (.github/workflows/ci.yml — flutter + dashboard)
- [x] Home empty-state when no medications + CTA to add
- [x] Late-confidence log on verification failure (monitor sees attempts)

Still requires external assets — out of pure code reach:
- [ ] FCM device-token registration (needs Firebase project + add `firebase_messaging` dep + iOS APNs cert)
- [ ] App icon — replace Flutter default in `android/.../mipmap-*` + `ios/.../AppIcon.appiconset` (need 1024×1024 PNG)
- [ ] Splash screen branding (need Lottie or PNG)
- [ ] Crashlytics / Sentry — add SDK + paste DSN
- [ ] Multi-medication CRUD UI extension (low value until you actually need 2nd med)
- [ ] Streak milestone Lottie animation (need .json asset)
- [ ] Schedule both Edge Functions in Supabase Cron: `daily-rollover` at 00:05 Asia/Manila, `storage-ttl` at 00:30 UTC

## 6. Phase 6 — PH market (future)

- [ ] PhilHealth prescription verification API integration
- [ ] Pharmacy partner refill reminders + delivery
- [ ] Barangay health center cohort dashboard (multi-patient view in Next.js)
- [ ] Tagalog / Filipino UI translations (`flutter_localizations`)
- [ ] Offline-first queue: local SQLite cache, background sync to Supabase when connectivity returns
- [ ] Freemium gate: free tier = reminders only; premium = verification + monitor dashboard

---

## 7. Ops / housekeeping

- [x] `.env` + `nextjs-dashboard/.env.local` in `.gitignore` — never commit real keys
- [ ] Rotate Supabase `service_role` if it ever leaks
- [ ] Rotate `WEBHOOK_SECRET` every 90 days (or on suspicion of leak) — `supabase secrets set WEBHOOK_SECRET=...` + update Database Webhook header in same dashboard transaction so no requests fail in between
- [ ] Storage TTL Edge Function deployed (Phase 5)
- [ ] Crashlytics dashboards alarmed (Phase 5)
- [ ] App icon + splash branding (Phase 5)
- [ ] Privacy policy + Terms of Service URLs in Play Store listing
- [ ] Dependabot / `flutter pub outdated` on a weekly cadence
- [ ] Branch protection on `main`: require all 4 CI jobs green + 1 review (GitHub UI per CONTRIBUTING.md)
- [ ] CodeQL or GitHub Advanced Security on the repo (free for public repos)

## 8. Known issues / debt

- [ ] 1 pub package flagged discontinued — run `flutter pub outdated` and swap before Play Store submit
- [ ] `flutter_overlay_window` v0.4.5 — confirm still maintained; alternative: `system_alert_window`
- [ ] Timezone hardcoded `Asia/Manila` in `notification_service.dart` — read from `users.timezone` once profile-edit UI lands
- [x] `bump_streak` SQL trigger does not handle missed-day reset → handled by `daily-rollover` Edge Function (cron-scheduled)
- [x] iOS lock = graceful no-op today → fixed by `LockGate` widget watching `lockedNotifier`
- [ ] No retry logic on Supabase Storage upload failure — verification photo may silently drop on flaky network
- [ ] RLS hardening: `users_update_self` policy lacks `with check`; add `with check (auth.uid() = id and role = 'patient')` before `role` ever gates server-side authz (currently no-op since `role` isn't consulted by any policy)
- [ ] Add Supabase Logflare / similar tail for `miss-alert` 401s — alert if > N per minute (indicates header misconfig or spray attack)

---

## 9. Security TODO (post-review)

- [x] `miss-alert` shared-secret + DB re-fetch (commit `0756365`)
- [ ] Deploy: rotate `WEBHOOK_SECRET` + update Database Webhook header (see §5)
- [ ] Add automated `deno test` smoke step locally before next push (`brew install deno && deno test supabase/functions/_tests/`)
- [ ] Run `/security-review` again before each tagged release
- [ ] Threat-model the FCM push body: ensure `patient.name` rendered server-side cannot contain injection payload that breaks Android notification rendering (extremely low risk, but worth a 30-min audit)
- [ ] Consider adding `signed_url_expires_at` to compliance_logs so dashboard can re-sign expired photo URLs server-side instead of failing silently
