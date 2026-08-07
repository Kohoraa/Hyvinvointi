-- ============================================================
-- Hyvinvointiseuranta – täydellinen tietokantaskeema
-- Aja tämä KOKONAISUUDESSAAN Supabase-projektisi SQL Editorissa
-- (Supabase-projekti → SQL Editor → liitä koko sisältö → Run).
--
-- Sisältää: ruokapäiväkirja, turvotusseuranta (tapahtumapohjainen),
-- liikuntapäiväkirja, ja käyttäjäprofiili energiataseen laskentaa
-- varten. Jokainen taulu on suojattu Row Level Securitylla niin,
-- että kirjautunut käyttäjä näkee ja muokkaa vain omia rivejään.
-- ============================================================

-- ------------------------------------------------------------
-- 1. RUOKAPÄIVÄKIRJA
-- ------------------------------------------------------------
create table food_entries (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  meal text not null,
  item text not null,
  kcal numeric,
  tags text[] default '{}',
  notes text,
  created_at timestamptz default now()
);

create index food_entries_user_date_idx on food_entries (user_id, entry_date);

alter table food_entries enable row level security;

create policy "own rows only - food select" on food_entries
  for select using (auth.uid() = user_id);
create policy "own rows only - food insert" on food_entries
  for insert with check (auth.uid() = user_id);
create policy "own rows only - food update" on food_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - food delete" on food_entries
  for delete using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 2. TURVOTUSSEURANTA (tapahtumapohjainen: vapaa määrä merkintöjä/päivä)
-- ------------------------------------------------------------
create table bloat_events (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  entry_time time not null default '12:00',
  bloat_level int check (bloat_level between 1 and 5) not null,
  waist_cm numeric,
  symptoms text,
  cause text,
  notes text,
  created_at timestamptz default now()
);

create index bloat_events_user_date_idx on bloat_events (user_id, entry_date, entry_time);

alter table bloat_events enable row level security;

create policy "own rows only - bloat select" on bloat_events
  for select using (auth.uid() = user_id);
create policy "own rows only - bloat insert" on bloat_events
  for insert with check (auth.uid() = user_id);
create policy "own rows only - bloat update" on bloat_events
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - bloat delete" on bloat_events
  for delete using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 3. LIIKUNTAPÄIVÄKIRJA
-- ------------------------------------------------------------
create table exercise_entries (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null,
  type text not null,
  duration_min numeric,
  intensity int check (intensity between 1 and 5),
  feeling text,
  notes text,
  created_at timestamptz default now()
);

create index exercise_entries_user_date_idx on exercise_entries (user_id, entry_date);

alter table exercise_entries enable row level security;

create policy "own rows only - exercise select" on exercise_entries
  for select using (auth.uid() = user_id);
create policy "own rows only - exercise insert" on exercise_entries
  for insert with check (auth.uid() = user_id);
create policy "own rows only - exercise update" on exercise_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - exercise delete" on exercise_entries
  for delete using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 4. KÄYTTÄJÄPROFIILI (energiataseen laskentaa varten)
-- ------------------------------------------------------------
create table user_profile (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  height_cm numeric,
  weight_kg numeric,
  age int,
  sex text check (sex in ('mies','nainen')),
  baseline_activity numeric default 1.2,
  updated_at timestamptz default now()
);

alter table user_profile enable row level security;

create policy "own profile select" on user_profile
  for select using (auth.uid() = user_id);
create policy "own profile insert" on user_profile
  for insert with check (auth.uid() = user_id);
create policy "own profile update" on user_profile
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own profile delete" on user_profile
  for delete using (auth.uid() = user_id);
