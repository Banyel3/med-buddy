# MedBuddy

Daily medication adherence, told in two voices: a warm patient app that
reminds, verifies and celebrates, and a quiet monitor dashboard that answers
"did they take it today?" in under three seconds.

Verification runs **on-device** — MLKit face detection plus a YOLOv8 pill model
via TFLite. Photos go to a private bucket, are readable only by the patient and
their linked monitor through short-lived signed URLs, and auto-delete after 30
days.

## Surfaces

| | Path | Stack |
|---|---|---|
| Patient app | `lib/`, `android/`, `ios/` | Flutter 3.41 · Riverpod · go_router |
| Monitor dashboard | `nextjs-dashboard/` | Next.js 14 · Tailwind · Supabase SSR |
| Backend | `supabase/` | Postgres + RLS · Deno Edge Functions |

The two clients are deliberately different brands — patient pink, monitor
violet. See `PRODUCT.md` for the reasoning and `DESIGN.md` for the tokens.

## Quick start

```bash
# 1. Backend — run supabase/schema.sql in the Supabase SQL editor,
#    then create a private storage bucket named `verifications`.

# 2. Patient app
cp .env.example .env          # fill SUPABASE_URL + SUPABASE_ANON_KEY
flutter pub get
flutter run --dart-define=MEDBUDDY_LOCK_MODE=soft

# 3. Monitor dashboard
cd nextjs-dashboard
cp .env.local.example .env.local   # fill the 3 keys
npm ci && npm run dev              # localhost:3000
```

`.env` is a bundled Flutter asset — the app will not build without it.

**Always develop with `MEDBUDDY_LOCK_MODE=soft`.** In `hard` mode the Android
lock overlay is only dismissed by completing a verification, which is exactly
as inconvenient as it sounds on a device you are debugging.

## The pill model

`assets/models/pills_detection.tflite` is a TFLite export of
[seblful/pills-detection](https://github.com/seblful/pills-detection) (CC BY
4.0, credited in-app). To regenerate:

```bash
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('best.pt').export(format='tflite')"
```

Without the model, pill confidence reads 0.0 and every verification fails
closed. The rest of the app runs fine.

## Docs

| File | What it is |
|---|---|
| `CLAUDE.md` | Architecture notes, known traps, conventions — read first |
| `PRODUCT.md` | Who this is for, brand voice, anti-references |
| `DESIGN.md` / `DESIGN.json` | Design system: color, type, components |
| `TESTING.md` | curl-level recipes: JWTs, mock logs, Edge Functions, lock QA |
| `CONTRIBUTING.md` | Hooks, local test commands, CI, branch protection |
| `TODO.md` | Remaining work, ordered |

## Development

Single long-lived branch: `main`. Branch off it, PR back, four CI jobs must be
green. `lefthook install` wires the format/analyze/test hooks.

## License

MIT — see `LICENSE`.
