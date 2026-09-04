# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

MedBuddy — medication adherence. Three deployable surfaces in one repo:

| Surface | Path | Stack |
|---|---|---|
| Patient app | `lib/`, `android/`, `ios/` | Flutter 3.41.x / Dart 3.11, Riverpod, go_router |
| Monitor dashboard | `nextjs-dashboard/` | Next.js 14 (App Router), Tailwind, Supabase SSR |
| Backend | `supabase/` | Postgres + RLS, Deno Edge Functions |

The two client surfaces are deliberately different brands: patient = pink/rose
(`lib/core/constants/app_colors.dart`), monitor = violet
(`nextjs-dashboard/tailwind.config.ts`). Do not unify them. See `PRODUCT.md`
and `DESIGN.md` for why.

## Toolchain reality on this machine

**Flutter, Dart and Deno are not installed here — only Node/npm.** Do not
promise that `flutter analyze` / `flutter test` / `deno test` passed; you
cannot run them locally. Dashboard checks (`npm run lint`, `npx tsc --noEmit`,
`npm test`) do run. Everything else is verified by CI on push
(`.github/workflows/ci.yml`).

State this limitation explicitly rather than implying local verification.

## Commands

```bash
# Dashboard (the only surface runnable locally)
cd nextjs-dashboard && npm ci
npm run dev            # localhost:3000
npm test               # vitest
npx tsc --noEmit
npm run lint

# Flutter (CI or a machine with the SDK)
flutter pub get
flutter analyze --fatal-infos
flutter test --coverage
flutter run --dart-define=MEDBUDDY_LOCK_MODE=soft   # never test hard lock casually

# Edge Functions
cd supabase && deno test --allow-env --allow-net functions/_tests/
```

`.env` at repo root is a **bundled Flutter asset** (declared in `pubspec.yaml`).
The app will not build without it. `cp .env.example .env` is what CI does.

## Architecture notes that are not obvious from the tree

**The Android lock is native Kotlin, not a pub package.**
`lib/features/lock/services/accessibility_lock_service.dart` is a `MethodChannel`
(`medbuddy/lock`) onto `android/app/src/main/kotlin/com/medbuddy/medbuddy/`
(`MainActivity`, `MedBuddyAccessibility`, `LockOverlayService`,
`LockAlarmScheduler`, `LockAlarmReceiver`). The `flutter_accessibility_service`
and `flutter_overlay_window` pub deps are **unused leftovers** — do not build on
them. iOS has no system overlay; `LockGate` renders an in-app modal instead.

**Three overlapping schedulers exist.** `flutter_local_notifications` (in-app
reminders), `workmanager` (`BackgroundScheduler`, 12-hourly re-arm), and native
`AlarmManager` (`scheduleLockAlarm`). They are not coordinated — see Known traps.

**Streaks are computed in Postgres**, by the `bump_streak` trigger in
`supabase/schema.sql`, with missed-day reset handled by the `daily-rollover`
Edge Function on `pg_cron`. Client never writes `streaks`.

**Auth profile rows are created by a DB trigger** (`handle_new_user`), reading
`role` from `raw_user_meta_data`. Dashboard signup passes `role=monitor`; the
mobile app omits it and falls through to `patient`.

## Known traps (verified in-tree, not yet fixed)

Read these before touching the relevant area:

1. `BackgroundScheduler._callbackDispatcher` calls
   `NotificationService.scheduleDailyReminder()` — a **hardcoded 12:30 PM
   "your medication"** schedule on fixed IDs 1001–1003. Every 12h it fights the
   real per-medication schedule set by `scheduleAllReminders`. Users get a
   phantom reminder and a phantom 13:00 lock.
2. `NotificationService.requestPermissions()` is **never called**. On Android 13+
   `POST_NOTIFICATIONS` is never requested, so reminders silently do not fire.
3. `nextMedicationProvider` returns `meds.first`, and the verification controller
   logs every dose against it. With two medications the wrong one is credited.
4. `pubspec.lock` and `ios/Podfile.lock` are matched by `*.lock` in `.gitignore`
   and are therefore **not committed** — builds are not reproducible, and the CI
   cache keys (`hashFiles('pubspec.lock')`) resolve to nothing.
5. `assets/models/pills_detection.tflite` is a **22 MB binary committed to git**.
6. `PillDetectionService._runInference` runs a 1.2M-element preprocessing loop
   plus a 16.8K-element scan on the UI isolate. It will jank.
7. `FaceDetectionService.detectFromFile` hardcodes `coverageRatio = 0.25`, which
   saturates `coverageScore` to 1.0. The 0.80 face threshold is effectively
   "a face is present". `PRODUCT.md` promises honest confidence rendering.
8. `compliance_logs` has no uniqueness constraint on
   `(user_id, medication_id, date)`, and failed verifications insert a `late` row
   each attempt. Repeated retries spam the monitor's calendar.
9. `TODO.md` is stale in places — e.g. it claims `users_update_self` lacks a
   `with check`, but `schema.sql` has one. Verify against code before trusting it.

## Conventions

- **Dart**: `dart format` is enforced by CI and by `lefthook` pre-commit.
  `flutter analyze --fatal-infos` — infos fail the build, so no stray TODOs in
  analyzer-visible positions.
- **Feature-first layout** under `lib/features/<feature>/`; anything shared by
  2+ features goes in `lib/shared/` or `lib/core/`. Providers live in
  `lib/shared/providers/`, one file per domain.
- **Spacing and radii come from `AppDimensions`**, colors from `AppColors`,
  type from `AppTextStyles`. No raw hex or magic numbers in feature widgets.
- **Dashboard**: Server Components by default; `'use client'` only where state or
  Supabase Realtime demands it (`RealtimeBridge`, forms, charts).
- **Secrets**: never commit `.env`, `.env.local`, or `SUPABASE_SERVICE_ROLE_KEY`.
  Edge Functions authenticate via `WEBHOOK_SECRET` with constant-time compare
  (`supabase/functions/_shared/security.ts`).

## Testing

`TESTING.md` holds the full curl-level recipes (JWT capture, mocking compliance
logs, firing Edge Functions, lock-mode QA). Use it rather than inventing new
fixtures. Unit tests cover models, `schedule_math`, `date_utils`, and the
verification controller; the lock and camera paths are real-device-only.

## Git

- Branch off `main`; PRs only. Four CI jobs must be green.
- Conventional commits (`feat:`, `fix:`, `chore:`, `build(deps):`), with an
  optional scope matching the surface: `fix(dashboard):`, `fix(ios):`,
  `feat(release):`.
- Dependabot runs weekly across `github-actions`, `npm` and `pub`. It has
  historically opened PRs for dependencies the app does not use — check whether a
  package is actually imported before merging its bump.
