# MedBuddy — TODO

Living checklist. Order = do top → bottom.

Everything here has been checked against the code as of the cleanup pass.
If an item and the code disagree, the code wins — fix the item.

---

## Phase status

| Phase | Code | Manual setup left |
|-------|------|-------------------|
| 1 — Foundation | ✅ | env + Supabase project |
| 2 — Verification | ✅ | real-device camera test |
| 3 — Android lock | ✅ | enable accessibility + overlay on device |
| 4 — Dashboard | ✅ | Vercel env vars, monitor_links row |
| 5 — Polish | ✅ code-side | icon, splash, FCM, Sentry DSN |
| 6 — PH market | ⏳ | future |

---

## 0. Blocking — before the next release

- [ ] Run the updated `supabase/schema.sql` against the live project. The
      cleanup added two things that are **not** yet applied to the running DB:
      the `compliance_logs_one_per_med_per_day` unique constraint and the
      `compliance_logs_protect_verified` trigger. Existing duplicate rows must
      be de-duplicated first or the constraint will fail to create:
      ```sql
      -- inspect first
      select user_id, medication_id, date, count(*)
      from compliance_logs group by 1,2,3 having count(*) > 1;
      ```
- [ ] `flutter pub get` on a machine with the SDK, then **commit the generated
      `pubspec.lock`**. It is newly un-ignored and the repo has never had one.
- [ ] `cd ios && pod install`, then commit `ios/Podfile.lock` for the same reason.
- [ ] Verify `tflite_flutter` 0.12 on device — the version bump was made for
      `IsolateInterpreter`, and the pill decode path changed with it.

## 1. Machine setup (once)

- [ ] `flutter doctor -v` — Android toolchain green
- [ ] AVD with an **ARM** image (API 34+), not x86
- [ ] Real Android device with USB debugging — the lock cannot be tested on an emulator
- [ ] Java 17 ≤ JDK < 25 (`flutter config --jdk-dir=<jdk17>` if Gradle complains)
- [ ] Node ≥ 18, npm ≥ 9
- [ ] `brew install supabase/tap/supabase` · `npm i -g vercel`
- [ ] `lefthook install`

## 2. Supabase

- [x] Project created; URL + anon key in `.env` and `nextjs-dashboard/.env.local`
- [x] `service_role` key in `nextjs-dashboard/.env.local`
- [x] `schema.sql` run — tables, enums, RLS, streak trigger
- [x] Private `verifications` storage bucket + the two `storage.objects` policies
- [x] Email auth provider enabled
- [x] Profile rows auto-created by the `handle_new_user` trigger
- [ ] Re-run `schema.sql` for the new constraint + trigger (see §0)
- [ ] Re-run `schema.sql` again for `compliance_logs.skipped_at` (dose alarm)

## 3. Edge Functions

- [x] `miss-alert` deployed (`--no-verify-jwt`), shared-secret + DB re-fetch
- [x] `daily-rollover` deployed, `WEBHOOK_SECRET`-gated
- [x] `storage-ttl` deployed, `WEBHOOK_SECRET`-gated
- [x] `WEBHOOK_SECRET` generated, stored in `vault.secrets` as `webhook_secret`
- [x] DB Webhook wired via `compliance_logs_miss_alert` trigger
- [x] `pg_cron`: `daily-rollover` at `5 16 * * *` UTC (00:05 Manila)
- [x] `pg_cron`: `storage-ttl` at `30 0 * * *` UTC
- [ ] `supabase secrets set FCM_SERVER_KEY=...`

## 4. Smoke tests

- [ ] `flutter run` — splash → login → onboarding → home
- [ ] Resize past 600dp → NavigationRail appears
- [ ] Grant the notification prompt at the end of onboarding step 2, then
      confirm a reminder fires at the chosen time (**not** 12:30 — the
      hardcoded 12:30 fallback was removed)
- [ ] Verification: capture → face → pill → upload → row in `compliance_logs`
- [ ] Retry a failed verification twice — confirm **one** row, not three
- [ ] Lock: trigger `lock-activate` → overlay → BACK/HOME bounce → verify → clear
- [ ] Lock on Samsung One UI (Knox) + Xiaomi MIUI / realme (autostart)
- [ ] Emergency dialer + Settings → Accessibility still pass through
- [ ] Dashboard live-updates when the patient verifies (Supabase Realtime)

## 4b. Dose alarm — release blockers

The alarm code is in, but Google Play gates two of the things it needs. Neither
is a code change; both are manual declarations that must land before release.

- [ ] **Play Console → Policy → App content → Full-screen intent.** Declare
      `USE_FULL_SCREEN_INTENT` with a justification. Since Jan 2025 it is
      default-granted only to calling and alarm apps; MedBuddy qualifies as an
      alarm app, but undeclared apps get it revoked.
- [ ] **Play Console → foreground service types.** Declare `specialUse` for
      `LockOverlayService`, with a description and demo video.
- [ ] Device-test on Samsung One UI (Knox) and Xiaomi MIUI / realme UI —
      autostart and battery restrictions kill alarms there first.
- [ ] Confirm the alarm survives a reboot (`setAlarmClock` is re-armed by the
      receiver, but the first arm after boot comes from Dart).

## 5. Still needs external assets

- [ ] FCM device-token registration (Firebase project + `firebase_messaging` + APNs cert)
- [ ] App icon — 1024×1024 PNG into `android/.../mipmap-*` + `ios/.../AppIcon.appiconset`
- [ ] Splash branding (Lottie or PNG)
- [ ] Crashlytics / Sentry SDK + DSN
- [ ] Streak milestone animation (.json)

## 6. Phase 6 — PH market (future)

- [ ] PhilHealth prescription verification API
- [ ] Pharmacy partner refill reminders + delivery
- [ ] Barangay health centre cohort dashboard (multi-patient view)
- [ ] Tagalog / Filipino UI (`flutter_localizations`)
- [ ] Offline-first queue: local SQLite cache, sync on reconnect
- [ ] Freemium gate: free = reminders; premium = verification + dashboard

## 7. Ops

- [x] `.env` + `.env.local` gitignored
- [x] `pubspec.lock` / `Podfile.lock` no longer gitignored
- [ ] Rotate `WEBHOOK_SECRET` every 90 days — update the Database Webhook
      header in the same transaction so no request 401s in between
- [ ] Rotate Supabase `service_role` if it ever leaks
- [ ] Branch protection on `main`: require the 4 CI jobs + 1 review
- [ ] Privacy policy + ToS URLs in the Play Store listing
- [ ] `flutter pub outdated` weekly (Dependabot covers the PRs)

## 8. Known issues / debt

Verified present in the code right now:

- [ ] **Timezone is hardcoded** to `Asia/Manila` in `notification_service.dart:init`.
      `users.timezone` exists in the schema and is never read. Any user outside
      PHT gets reminders at the wrong local time.
- [ ] **No retry on Storage upload failure** — a verification photo can silently
      drop on a flaky network; the log row is written either way.
- [ ] **R8 disabled for release** (`android/app/build.gradle.kts`) because it
      strips TFLite GPU delegate classes. Needs proguard rules before Play
      Store submission; the APK is larger than it should be until then.
- [ ] **Release builds are signed with the debug key.** Blocks Play Store.
- [ ] **22 MB `pills_detection.tflite` is committed to git.** Repo is ~21 MB as
      a result. Not urgent at one copy; becomes a real problem if the model is
      ever re-exported and re-committed. Decide on Git LFS before that happens.
- [ ] `_scoreFromFaces` is a heuristic (frame coverage + smile/eye
      probabilities), not a real face-match. It confirms *a* face is close to
      the camera, not *whose*. Fine for the current product claim — do not let
      the UI imply identity verification.
- [ ] No `Logflare`/tail alert on `miss-alert` 401s (would indicate a
      misconfigured header or a spray attack).
- [ ] Consider `signed_url_expires_at` on `compliance_logs` so the dashboard can
      re-sign expired photo URLs instead of failing silently.

Fixed in the cleanup pass — kept here so they are not "rediscovered":

- [x] Workmanager re-armed a hardcoded 12:30 reminder every 12h, fighting the
      real per-medication schedule. Whole scheduler deleted.
- [x] `POST_NOTIFICATIONS` was never requested — reminders were silent on
      Android 13+. Now requested at the end of onboarding step 2.
- [x] `nextMedicationProvider` returned `meds.first`, crediting the earliest
      medication of the day for every dose. Now picks the nearest scheduled.
- [x] `pubspec.lock` / `Podfile.lock` were gitignored by a bare `*.lock`.
- [x] Six unused dependencies removed; two of them had open Dependabot PRs.
- [x] `medication_id: ''` was sent to a `uuid` column on the no-medication path.
- [x] Failed verifications inserted a new `late` row per attempt.
- [x] Onboarding collected a "Frequency" value that was never stored anywhere.
- [x] `users_update_self` has a `with check` — an earlier TODO claimed it did not.
- [x] Pill inference ran on the UI isolate.

## 9. Security

- [x] `miss-alert` shared-secret + DB re-fetch (commit `0756365`)
- [x] `protect_verified_log` trigger — a verified dose cannot be downgraded
- [ ] Rotate `WEBHOOK_SECRET` + update the webhook header (see §7)
- [ ] `deno test supabase/functions/_tests/` locally before pushing Edge changes
- [ ] Run `/security-review` before each tagged release
- [ ] Threat-model the FCM push body: confirm `patient.name` cannot break
      Android notification rendering (low risk, ~30 min audit)
