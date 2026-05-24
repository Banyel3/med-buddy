# MedBuddy — TODO

Living checklist. Tick as done. Order = do top→bottom.

---

## 0. One-time machine setup (you, before next `flutter run`)

- [ ] `flutter doctor -v` — confirm Android toolchain green
- [ ] Android Studio installed → Device Manager → create AVD with **ARM image** (API 34+), NOT x86 (M4 chip)
- [ ] Plug in real Android device (Samsung A / Redmi / realme) → enable USB debugging → `flutter devices` shows it
- [ ] Java 17 ≤ JDK < 25 — current Java may conflict with Gradle 8.14 (warning during `flutter create`). Fix: `flutter config --jdk-dir=<path-to-jdk17>` if Gradle errors

## 1. Supabase project (blocks login + everything backend)

- [ ] Create project at https://supabase.com (free tier OK)
- [ ] Copy `Project URL` + `anon public` key → paste into `.env`
- [ ] Run schema SQL (PRD §7) — create tables: `users`, `monitor_links`, `medications`, `compliance_logs`, `streaks`
  - [ ] Enable Row Level Security on each table
  - [ ] Policy: patient reads own rows; monitor reads via `monitor_links` join
- [ ] Storage → create private bucket `verifications` (signed URL only)
- [ ] Auth → enable Email provider; disable email confirmation in dev for fast iteration
- [ ] Sanity check: `flutter run` → sign up → confirm row appears in `auth.users`

## 2. Phase 1 smoke test

- [ ] `flutter pub get`
- [ ] `flutter analyze` — must report **No issues found**
- [ ] `flutter run` on ARM emulator — boots to splash → login
- [ ] Sign up → onboarding flow → land on Home with adaptive scaffold
- [ ] Resize emulator past 600dp width → NavigationRail appears (tablet mode)
- [ ] History tab → empty calendar renders
- [ ] Notifications: grant permission when asked; verify 12:30 PM reminder fires (test by changing system clock)

## 3. Phase 2 — Verification (AI vision)

- [ ] Clone `seblful/pills-detection`, grab `best.pt`
- [ ] `pip install ultralytics` → `python -c "from ultralytics import YOLO; YOLO('best.pt').export(format='tflite')"`
- [ ] Drop `pills_detection.tflite` into `assets/models/`
- [ ] Implement `lib/features/verification/services/face_detection_service.dart` (google_mlkit_face_detection)
- [ ] Implement `lib/features/verification/services/pill_detection_service.dart` (tflite_flutter)
- [ ] Build real `verification_screen.dart` — camera preview + face oval + pill box + dual-confidence gate
- [ ] On success: capture frame → upload to `verifications` bucket → write `compliance_logs` row → bump `streaks`
- [ ] On failure: friendly retry, no miss count
- [ ] Add seblful credit to in-app credits (CC BY 4.0)

## 4. Phase 3 — Android accessibility lock (real device only)

- [ ] Flesh out `MedBuddyAccessibility.kt` — intercept BACK + HOME, listen window state changes
- [ ] Create `LockOverlayService.kt` — `TYPE_ACCESSIBILITY_OVERLAY` window
- [ ] `accessibility_lock_service.dart` — MethodChannel bridge (`activate` / `deactivate`)
- [ ] Onboarding deep-link to Settings → Accessibility → MedBuddy, wait for grant
- [ ] Wire T+30min escalation notification → `activate()`
- [ ] Wire verification success → `deactivate()`
- [ ] Fallback: if perm denied → in-app full-screen modal (no crash)
- [ ] Test on min 2 devices (Samsung One UI + Xiaomi MIUI / realme UI)

## 5. Phase 4 — Next.js monitor dashboard

- [ ] `npx create-next-app@latest nextjs-dashboard --typescript --tailwind --app` (sibling dir)
- [ ] Tailwind theme tokens = MedBuddy palette (PRD §8.1)
- [ ] `npm i @supabase/supabase-js recharts`
- [ ] Pages: dashboard (miss banner + today hero + 7-day bar chart + photo grid + month calendar + streak)
- [ ] Supabase Realtime subscription on `compliance_logs`
- [ ] Supabase Edge Function (Deno) — fires on `status → missed`, sends FCM/web push to monitor
- [ ] `vercel --prod` deploy

## 6. Phase 5 — Polish

- [ ] Lottie pill mascot for lock + verification success
- [ ] Streak milestone animation on each milestone day
- [ ] Multi-medication UI (morning + evening schedules)
- [ ] Onboarding fine-tune (timer feels < 5 min end-to-end)
- [ ] Empty states for History + Home when zero data
- [ ] Dark mode pass (PRD doesn't require but worth ~2hr)

## 7. Ops / housekeeping

- [ ] `.env` is in `.gitignore` — never commit real keys
- [ ] Storage TTL Edge Function — purge verification images > 30 days
- [ ] Crashlytics or Sentry hook in `main.dart`
- [ ] App icon + splash branding (replace Flutter default)
- [ ] Privacy policy page (required for Play Store + camera perm)

## 8. Known issues / debt

- 1 pub package flagged discontinued — run `flutter pub outdated` and swap before Play Store submit
- `flutter_overlay_window` v0.4.5 — confirm still maintained at Phase 3 start; alternative: `system_alert_window`
- Timezone hardcoded `Asia/Manila` in `notification_service.dart` — read from `users.timezone` once profile is wired
