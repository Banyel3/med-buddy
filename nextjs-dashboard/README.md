# MedBuddy Monitor Dashboard

Next.js 14 + Tailwind + Supabase Realtime — caregiver view for MedBuddy
adherence tracking.

## Setup

```bash
cd nextjs-dashboard
npm install
cp .env.local.example .env.local   # then fill values
npm run dev
```

Open http://localhost:3000.

## Env

| Key | Where to get it |
|-----|----------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase Project Settings → API |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase Project Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Project Settings → API (server-only) |

## Schema

Run `../supabase/schema.sql` in the Supabase SQL editor before first
sign-in. It provisions tables, RLS policies, and a streak bump trigger.

## Deploy

```bash
vercel --prod
```

Set the same env vars in the Vercel project settings.

## Miss-alert Edge Function

```bash
cd ../supabase
supabase functions deploy miss-alert
supabase secrets set FCM_SERVER_KEY=...
```

Add a Database Webhook in the Supabase dashboard:
- Table: `compliance_logs`
- Event: UPDATE
- Condition: `new.status = 'missed' AND old.status != 'missed'`
- URL: your function URL

## Architecture

- Server component `app/dashboard/page.tsx` fetches today's log + 120
  recent logs + streak via `@supabase/ssr` cookies-based auth.
- `RealtimeBridge` client component subscribes to
  `compliance_logs` + `streaks` postgres_changes and calls
  `router.refresh()` on every event so server components re-fetch.
- Tailwind theme tokens mirror the mobile Flutter palette (PRD §8.1).
