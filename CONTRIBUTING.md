# Contributing to MedBuddy

## One-time setup

```bash
# 1. Pre-commit / pre-push hooks
brew install lefthook
lefthook install

# 2. Flutter deps
flutter pub get

# 3. Dashboard deps
cd nextjs-dashboard && npm install && cd ..

# 4. Optional — Deno (only if you'll edit Supabase Edge Functions)
brew install deno
```

After `lefthook install`, every `git commit` runs `dart format` + Prettier,
and every `git push` runs the full test + analyze + type-check suite in
parallel. To bypass in an emergency: `LEFTHOOK=0 git push` (avoid).

## Running tests locally

```bash
# Flutter
flutter analyze
flutter test --coverage          # writes coverage/lcov.info

# Dashboard
cd nextjs-dashboard
npm run lint
npm test                          # vitest run
npm run build                     # SSR/build smoke

# Edge Functions
cd supabase
deno test --allow-env --allow-net functions/_tests/
```

## CI

`.github/workflows/ci.yml` runs four parallel jobs on every push to
`main` + every PR:

| Job | Runs |
|-----|------|
| `flutter` | format check, `flutter analyze`, `flutter test --coverage` (artifact uploaded) |
| `flutter-build` | `flutter build apk --debug` (catches Gradle / manifest regressions) |
| `dashboard` | `tsc --noEmit`, `next lint`, `vitest run`, `next build` |
| `edge-functions` | `deno test` on `supabase/functions/_tests/` |

## Supabase Edge Function secrets

`miss-alert` requires a shared secret to be set on both the function env
and the Database Webhook config. Without it, the function returns 401.

```bash
# Generate a strong secret once:
SECRET=$(openssl rand -hex 32)

# Set on the function env:
supabase secrets set WEBHOOK_SECRET="$SECRET"
supabase secrets set FCM_SERVER_KEY=<firebase-server-key>

# Then in Supabase Dashboard → Database → Webhooks → Edit miss-alert:
#   add HTTP header `x-webhook-secret: <SECRET>`
```

The function does NOT trust `record.user_id` / `record.status` from the
webhook payload — it re-reads the `compliance_logs` row by `record.id`
and acts only on the database state. This prevents payload spoofing
even if the secret leaks.

## Branch protection (do this once in the GitHub UI)

Settings → Branches → Add rule for `main`:

- [x] Require a pull request before merging
- [x] Require status checks to pass: select all 4 CI jobs above
- [x] Require linear history (optional)
- [x] Do not allow bypassing the above settings
- [ ] Allow force pushes — leave unchecked

## Writing tests

| Layer | Where | Framework |
|-------|-------|-----------|
| Pure-Dart logic (models, utils, math) | `test/` mirrors `lib/` | `flutter_test` |
| Controllers + services | `test/` | `flutter_test` + `mocktail` |
| Widgets | `test/widgets/` | `flutter_test` + `pumpWidget` |
| Dashboard components | `nextjs-dashboard/**/__tests__/` | Vitest + `@testing-library/react` |
| Edge Functions | `supabase/functions/_tests/` | Deno `Deno.test` |

A test is required for any new branch in `verification_controller`,
any new field added to a model, or any new pure helper. Smoke tests
are enough for new widgets / pages.
