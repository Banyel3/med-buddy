-- MedBuddy Supabase schema (PRD §7).
-- Run in the Supabase SQL editor once, then enable Row Level Security.
-- ---------------------------------------------------------------

create extension if not exists "uuid-ossp";

-- Users -----------------------------------------------------------
create type user_role as enum ('patient', 'monitor');

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  role user_role not null default 'patient',
  timezone text not null default 'Asia/Manila',
  created_at timestamptz not null default now()
);

-- Monitor links ---------------------------------------------------
create table if not exists public.monitor_links (
  id uuid primary key default uuid_generate_v4(),
  patient_id uuid not null references public.users(id) on delete cascade,
  monitor_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (patient_id, monitor_id)
);

-- Medications -----------------------------------------------------
create table if not exists public.medications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  schedule_time time not null,
  notes text default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Compliance logs -------------------------------------------------
create type compliance_status as enum ('pending', 'verified', 'late', 'missed');

create table if not exists public.compliance_logs (
  id uuid primary key default uuid_generate_v4(),
  medication_id uuid references public.medications(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  status compliance_status not null default 'pending',
  image_url text,
  verified_at timestamptz,
  face_confidence real,
  pill_confidence real,
  created_at timestamptz not null default now()
);
create index if not exists compliance_logs_user_date_idx
  on public.compliance_logs (user_id, date desc);

-- Streaks ---------------------------------------------------------
create table if not exists public.streaks (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique not null references public.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_verified_date date,
  updated_at timestamptz not null default now()
);

-- Device tokens for FCM push (used by miss-alert Edge Function) ---
create table if not exists public.device_tokens (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

-- Streak maintenance trigger -------------------------------------
create or replace function public.bump_streak()
returns trigger language plpgsql as $$
declare
  prev streaks%rowtype;
begin
  if new.status <> 'verified' then return new; end if;
  select * into prev from public.streaks where user_id = new.user_id;
  if not found then
    insert into public.streaks (user_id, current_streak, longest_streak,
                                last_verified_date, updated_at)
    values (new.user_id, 1, 1, new.date, now());
    return new;
  end if;
  if prev.last_verified_date = new.date then
    return new; -- already counted today
  end if;
  if prev.last_verified_date = new.date - interval '1 day' then
    update public.streaks
    set current_streak = prev.current_streak + 1,
        longest_streak = greatest(prev.longest_streak, prev.current_streak + 1),
        last_verified_date = new.date,
        updated_at = now()
    where user_id = new.user_id;
  else
    update public.streaks
    set current_streak = 1,
        longest_streak = greatest(prev.longest_streak, 1),
        last_verified_date = new.date,
        updated_at = now()
    where user_id = new.user_id;
  end if;
  return new;
end $$;

drop trigger if exists compliance_logs_bump_streak on public.compliance_logs;
create trigger compliance_logs_bump_streak
  after insert or update on public.compliance_logs
  for each row execute function public.bump_streak();

-- Row Level Security ---------------------------------------------
alter table public.users enable row level security;
alter table public.monitor_links enable row level security;
alter table public.medications enable row level security;
alter table public.compliance_logs enable row level security;
alter table public.streaks enable row level security;
alter table public.device_tokens enable row level security;

-- users: read self + any linked party
create policy "users_read_self" on public.users
  for select using (auth.uid() = id);
create policy "users_read_linked" on public.users
  for select using (
    exists (
      select 1 from public.monitor_links ml
      where (ml.patient_id = users.id and ml.monitor_id = auth.uid())
         or (ml.monitor_id = users.id and ml.patient_id = auth.uid())
    )
  );
create policy "users_upsert_self" on public.users
  for insert with check (auth.uid() = id);
create policy "users_update_self" on public.users
  for update
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and role = (select role from public.users where id = auth.uid())
  );

-- monitor_links: both parties read; patient inserts
create policy "links_read" on public.monitor_links for select using (
  patient_id = auth.uid() or monitor_id = auth.uid()
);
create policy "links_insert_patient" on public.monitor_links
  for insert with check (patient_id = auth.uid());
create policy "links_delete_either" on public.monitor_links
  for delete using (patient_id = auth.uid() or monitor_id = auth.uid());

-- medications: owner only
create policy "meds_owner_read" on public.medications
  for select using (user_id = auth.uid() or exists (
    select 1 from public.monitor_links
    where patient_id = medications.user_id and monitor_id = auth.uid()
  ));
create policy "meds_owner_write" on public.medications
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- compliance_logs: owner reads/writes; monitor reads
create policy "logs_owner_read" on public.compliance_logs
  for select using (user_id = auth.uid() or exists (
    select 1 from public.monitor_links
    where patient_id = compliance_logs.user_id and monitor_id = auth.uid()
  ));
create policy "logs_owner_write" on public.compliance_logs
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- streaks: same shape as compliance_logs
create policy "streaks_owner_read" on public.streaks
  for select using (user_id = auth.uid() or exists (
    select 1 from public.monitor_links
    where patient_id = streaks.user_id and monitor_id = auth.uid()
  ));
create policy "streaks_owner_write" on public.streaks
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- device_tokens: owner only
create policy "tokens_owner_read" on public.device_tokens
  for select using (user_id = auth.uid());
create policy "tokens_owner_write" on public.device_tokens
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "tokens_delete_owner" on public.device_tokens
  for delete using (user_id = auth.uid());

-- New auth user -> public.users profile -------------------------
-- Auto-create the profile row when a user confirms (or signs up if email
-- confirmation is off) so the app never lands on a missing-profile state.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, name, role, timezone)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'name'), ''),
      split_part(new.email, '@', 1)
    ),
    -- Dashboard signups pass role='monitor' in user metadata; mobile
    -- app signups omit the field and fall through to 'patient'. Cast
    -- to the user_role enum so forged values (e.g. 'admin') error out.
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'role'), '')::user_role,
      'patient'::user_role
    ),
    coalesce(nullif(trim(new.raw_user_meta_data->>'timezone'), ''), 'Asia/Manila')
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Storage bucket (run in SQL editor too) -------------------------
-- insert into storage.buckets (id, name, public) values ('verifications', 'verifications', false)
--   on conflict (id) do nothing;
-- create policy "verifications_owner_read" on storage.objects
--   for select using (bucket_id = 'verifications' and owner = auth.uid());
-- create policy "verifications_owner_write" on storage.objects
--   for insert with check (bucket_id = 'verifications' and owner = auth.uid());
