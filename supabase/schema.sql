-- ============================================================
--  DAILY QUEST — Supabase schema
--  Paste this whole file into:  Supabase Dashboard → SQL Editor → New query → Run
--  Safe to re-run (uses IF NOT EXISTS / OR REPLACE).
-- ============================================================

-- ---------- PROFILES (one row per user, progression state) ----------
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  display_name    text,
  total_days      integer not null default 0,
  streak          integer not null default 0,
  last_date       date,                       -- last day a quest was completed (yyyy-mm-dd)
  pending_penalty boolean not null default false,
  missed_days     integer not null default 0,
  reminder_hour   integer not null default 8, -- local hour for the daily reminder notification
  reminder_minute integer not null default 0,
  onboarded       boolean not null default false,
  grace_used      boolean not null default false, -- one-time "first miss" warning spent?
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- If you ran an earlier version of this schema, add the new columns:
alter table public.profiles
  add column if not exists onboarded boolean not null default false;
alter table public.profiles
  add column if not exists grace_used boolean not null default false;

-- ---------- CUSTOM EXERCISES (the user's own exercise library) ----------
-- kind = 'reps'  -> target is a rep count
-- kind = 'time'  -> target is seconds to hold/perform
-- for_date null  -> a permanent daily exercise
-- for_date set   -> a one-off planned ONLY for that specific date (tomorrow's extra workout)
create table if not exists public.exercises (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  icon        text not null default '⚡',
  kind        text not null default 'reps' check (kind in ('reps','time')),
  target      integer not null default 10,
  for_date    date,
  active      boolean not null default true,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists exercises_user_idx on public.exercises(user_id);
create index if not exists exercises_for_date_idx on public.exercises(user_id, for_date);

-- ---------- DAILY STATE (per-day completion of each exercise) ----------
-- checks: jsonb map of { exercise_id: true/false }
create table if not exists public.daily_state (
  user_id    uuid not null references auth.users(id) on delete cascade,
  day        date not null,
  checks     jsonb not null default '{}'::jsonb,
  completed  boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, day)
);

-- ---------- HISTORY (completed days) ----------
create table if not exists public.quest_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  primary key (user_id, day)
);

-- ---------- PENALTIES (days a penalty was applied) ----------
create table if not exists public.penalties (
  user_id uuid not null references auth.users(id) on delete cascade,
  day     date not null,
  amount  integer not null default 0,
  primary key (user_id, day)
);

-- ============================================================
--  ROW LEVEL SECURITY — each user can only touch their own rows
-- ============================================================
alter table public.profiles      enable row level security;
alter table public.exercises     enable row level security;
alter table public.daily_state   enable row level security;
alter table public.quest_history enable row level security;
alter table public.penalties     enable row level security;

-- profiles
drop policy if exists "profiles_self" on public.profiles;
create policy "profiles_self" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- generic per-user policies (user_id column)
drop policy if exists "exercises_self" on public.exercises;
create policy "exercises_self" on public.exercises
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "daily_state_self" on public.daily_state;
create policy "daily_state_self" on public.daily_state
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "quest_history_self" on public.quest_history;
create policy "quest_history_self" on public.quest_history
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "penalties_self" on public.penalties;
create policy "penalties_self" on public.penalties
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
--  AUTO-CREATE a profile + starter exercises when a user signs up
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  -- Pull a name from email/password signup metadata or a Google profile.
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(
    new.raw_user_meta_data->>'display_name',
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    'Hunter'))
  on conflict (id) do nothing;

  -- No starter exercises are seeded: the app prescribes a full workout per
  -- rank (see lib/data/rank_programs.dart). The `exercises` table holds only
  -- the user's own custom additions.
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
