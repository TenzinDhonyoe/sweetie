-- ============================================================
-- Close To You — Initial Schema
-- ============================================================

-- Helper: generate a 6-char invite code (no ambiguous chars)
create or replace function generate_invite_code()
returns text
language plpgsql
as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code  text;
  i     int;
begin
  loop
    code := '';
    for i in 1..6 loop
      code := code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    end loop;
    exit when not exists (select 1 from couples where invite_code = code);
  end loop;
  return code;
end;
$$;

-- ============================================================
-- Tables
-- ============================================================

create table profiles (
  id           uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_url   text,
  timezone     text,
  sleep_start  time default '23:00',
  sleep_end    time default '07:00',
  push_token   text,
  created_at   timestamptz default now()
);

create table couples (
  id           uuid primary key default gen_random_uuid(),
  partner_1    uuid not null references profiles on delete cascade,
  partner_2    uuid references profiles on delete set null,
  invite_code  text unique not null default generate_invite_code(),
  reunion_date timestamptz,
  created_at   timestamptz default now()
);

create table taps (
  id         uuid primary key default gen_random_uuid(),
  couple_id  uuid not null references couples on delete cascade,
  sender_id  uuid not null references profiles on delete cascade,
  pattern    text,
  emoji      text,
  created_at timestamptz default now()
);

create table photos (
  id           uuid primary key default gen_random_uuid(),
  couple_id    uuid not null references couples on delete cascade,
  sender_id    uuid not null references profiles on delete cascade,
  storage_path text not null,
  caption      text,
  reaction     text,
  created_at   timestamptz default now()
);

create table love_notes (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references couples on delete cascade,
  sender_id      uuid not null references profiles on delete cascade,
  content        text not null,
  category       text not null check (category in ('instant', 'open_when', 'morning', 'night')),
  open_when_label text,
  deliver_at     timestamptz,
  delivered      boolean default false,
  read           boolean default false,
  created_at     timestamptz default now()
);

create table daily_questions (
  id               uuid primary key default gen_random_uuid(),
  couple_id        uuid not null references couples on delete cascade,
  question_text    text not null,
  day_number       int not null check (day_number between 1 and 10),
  partner_1_answer text,
  partner_2_answer text,
  unlocked_at      timestamptz,
  created_at       timestamptz default now()
);

-- ============================================================
-- Helper: get couple_id for a user (used in RLS)
-- ============================================================

create or replace function get_couple_id(user_id uuid)
returns uuid
language sql
stable
security definer
as $$
  select id from couples
  where partner_1 = user_id or partner_2 = user_id
  limit 1;
$$;

-- ============================================================
-- Trigger: auto-create profile on signup
-- ============================================================

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================
-- RPC: join a couple via invite code
-- ============================================================

create or replace function join_couple(code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  couple_row couples%rowtype;
begin
  select * into couple_row
  from couples
  where invite_code = upper(code)
  limit 1;

  if couple_row.id is null then
    raise exception 'Invalid invite code';
  end if;

  if couple_row.partner_2 is not null then
    raise exception 'This couple already has two partners';
  end if;

  if couple_row.partner_1 = auth.uid() then
    raise exception 'You cannot join your own couple';
  end if;

  update couples
  set partner_2 = auth.uid()
  where id = couple_row.id;

  return couple_row.id;
end;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================

alter table profiles enable row level security;
alter table couples enable row level security;
alter table taps enable row level security;
alter table photos enable row level security;
alter table love_notes enable row level security;
alter table daily_questions enable row level security;

-- profiles
create policy "Users can view own profile"
  on profiles for select using (id = auth.uid());
create policy "Users can view partner profile"
  on profiles for select using (id in (
    select partner_1 from couples where partner_2 = auth.uid()
    union
    select partner_2 from couples where partner_1 = auth.uid()
  ));
create policy "Users can update own profile"
  on profiles for update using (id = auth.uid());

-- couples
create policy "Users can view own couple"
  on couples for select using (partner_1 = auth.uid() or partner_2 = auth.uid());
create policy "Users can create couple as partner_1"
  on couples for insert with check (partner_1 = auth.uid());
create policy "Users can update own couple"
  on couples for update using (partner_1 = auth.uid() or partner_2 = auth.uid());

-- taps
create policy "Users can view couple taps"
  on taps for select using (couple_id = get_couple_id(auth.uid()));
create policy "Users can send taps"
  on taps for insert with check (
    couple_id = get_couple_id(auth.uid()) and sender_id = auth.uid()
  );

-- photos
create policy "Users can view couple photos"
  on photos for select using (couple_id = get_couple_id(auth.uid()));
create policy "Users can send photos"
  on photos for insert with check (
    couple_id = get_couple_id(auth.uid()) and sender_id = auth.uid()
  );
create policy "Users can update couple photos"
  on photos for update using (couple_id = get_couple_id(auth.uid()));

-- love_notes
create policy "Users can view couple notes"
  on love_notes for select using (couple_id = get_couple_id(auth.uid()));
create policy "Users can send notes"
  on love_notes for insert with check (
    couple_id = get_couple_id(auth.uid()) and sender_id = auth.uid()
  );
create policy "Users can update couple notes"
  on love_notes for update using (couple_id = get_couple_id(auth.uid()));

-- daily_questions
create policy "Users can view couple questions"
  on daily_questions for select using (couple_id = get_couple_id(auth.uid()));
create policy "Users can insert couple questions"
  on daily_questions for insert with check (couple_id = get_couple_id(auth.uid()));
create policy "Users can update couple questions"
  on daily_questions for update using (couple_id = get_couple_id(auth.uid()));

-- ============================================================
-- Realtime
-- ============================================================

alter publication supabase_realtime add table couples;
alter publication supabase_realtime add table photos;
