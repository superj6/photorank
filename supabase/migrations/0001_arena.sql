-- PhotoRank Arena: daily global photo game.
-- Apply with: supabase db push   (or psql "$DATABASE_URL" -f this file)

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text,
  banned boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- -------------------------------------------------------------------- days
create table if not exists public.days (
  day date primary key,
  axis text not null default 'love',
  theme text,
  closes_at timestamptz not null,
  finalized boolean not null default false
);

create or replace function public.arena_today() returns date
language sql stable as $$ select (now() at time zone 'utc')::date $$;

create or replace function public.ensure_day(p_day date) returns void
language sql security definer set search_path = public as $$
  insert into public.days (day, closes_at)
  values (p_day, (p_day + 1)::timestamp at time zone 'utc')
  on conflict do nothing
$$;

-- Rating is allowed until close + 4h grace.
create or replace function public.day_open(p_day date) returns boolean
language sql stable as $$
  select now() < (select closes_at + interval '4 hours' from public.days where day = p_day)
$$;

-- ------------------------------------------------------------------- rooms
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null check (char_length(name) between 1 and 40),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  axis text not null default 'love',
  created_at timestamptz not null default now()
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

-- ----------------------------------------------------------------- entries
create table if not exists public.entries (
  id uuid primary key default gen_random_uuid(),
  day date not null references public.days (day),
  user_id uuid not null references public.profiles (id) on delete cascade,
  room_id uuid references public.rooms (id) on delete cascade,   -- null = global
  storage_path text not null,
  mu double precision not null default 1500,
  rd double precision not null default 350,
  duels integer not null default 0,
  wins integer not null default 0,
  status text not null default 'active' check (status in ('active', 'hidden', 'deleted')),
  final_rank integer,
  created_at timestamptz not null default now(),
  unique nulls not distinct (day, user_id, room_id)
);
create index if not exists entries_board_idx on public.entries (day, room_id, status, mu desc);

-- ------------------------------------------------------------------- duels
create table if not exists public.duels (
  id bigserial primary key,
  day date not null,
  rater_id uuid not null references public.profiles (id) on delete cascade,
  a_id uuid not null references public.entries (id) on delete cascade,
  b_id uuid not null references public.entries (id) on delete cascade,
  winner_id uuid not null references public.entries (id) on delete cascade,
  lo uuid generated always as (least(a_id, b_id)) stored,
  hi uuid generated always as (greatest(a_id, b_id)) stored,
  created_at timestamptz not null default now(),
  unique (rater_id, lo, hi)
);
create index if not exists duels_rater_day_idx on public.duels (rater_id, day);

-- ------------------------------------------------------ social + moderation
create table if not exists public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table if not exists public.reports (
  entry_id uuid not null references public.entries (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null default 'other',
  created_at timestamptz not null default now(),
  primary key (entry_id, reporter_id)
);

-- Three reports hide an entry pending review.
create or replace function public.hide_reported() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.reports where entry_id = new.entry_id) >= 3 then
    update public.entries set status = 'hidden' where id = new.entry_id and status = 'active';
  end if;
  return new;
end $$;
drop trigger if exists on_report on public.reports;
create trigger on_report after insert on public.reports
  for each row execute function public.hide_reported();

-- ------------------------------------------------------------------ glicko
-- Same maths as lib/core/rating/glicko.dart (Glicko-1, sequential updates).
create or replace function public.glicko_g(rd double precision) returns double precision
language sql immutable as $$
  select 1.0 / sqrt(1.0 + 3.0 * power(ln(10.0) / 400.0, 2) * rd * rd / power(pi(), 2))
$$;

create or replace function public.glicko_expected(mu_a double precision, mu_b double precision, rd_b double precision)
returns double precision language sql immutable as $$
  select 1.0 / (1.0 + power(10.0, -public.glicko_g(rd_b) * (mu_a - mu_b) / 400.0))
$$;

-- Returns the updated (mu, rd) for a after facing b with score s (1 win, 0.5 draw, 0 loss).
create or replace function public.glicko_update(mu_a double precision, rd_a double precision,
                                                mu_b double precision, rd_b double precision,
                                                s double precision,
                                                out new_mu double precision, out new_rd double precision)
language plpgsql immutable as $$
declare
  q constant double precision := ln(10.0) / 400.0;
  gb double precision := public.glicko_g(rd_b);
  e double precision := public.glicko_expected(mu_a, mu_b, rd_b);
  d2 double precision;
  inv double precision := 1.0 / (rd_a * rd_a);
begin
  d2 := 1.0 / (q * q * gb * gb * e * (1.0 - e));
  new_mu := mu_a + q / (inv + 1.0 / d2) * gb * (s - e);
  new_rd := greatest(30.0, least(350.0, sqrt(1.0 / (inv + 1.0 / d2))));
end $$;

-- --------------------------------------------------------------- functions
create or replace function public.submit_entry(p_room uuid, p_storage_path text) returns public.entries
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  d date := public.arena_today();
  row public.entries;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if (select banned from public.profiles where id = uid) then raise exception 'banned'; end if;
  if p_room is not null and not exists (select 1 from public.room_members where room_id = p_room and user_id = uid) then
    raise exception 'not a member of this room';
  end if;
  if p_storage_path not like uid::text || '/%' then raise exception 'bad storage path'; end if;
  perform public.ensure_day(d);
  insert into public.entries (day, user_id, room_id, storage_path)
  values (d, uid, p_room, p_storage_path)
  returning * into row;
  return row;
exception when unique_violation then
  raise exception 'already submitted today';
end $$;

create or replace function public.delete_entry(p_entry uuid) returns void
language sql security definer set search_path = public as $$
  update public.entries set status = 'deleted' where id = p_entry and user_id = auth.uid()
$$;

-- Info-maximising pairs for the rater: never their own entry, never a
-- blocked user, never a pair they already rated. Prefers uncertain entries
-- and near-equal opponents.
create or replace function public.next_pairs(p_room uuid, p_n integer default 10)
returns table (a_id uuid, b_id uuid, a_path text, b_path text)
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  d date := public.arena_today();
  a record;
  b record;
  taken uuid[] := '{}';
  produced integer := 0;
begin
  if uid is null then raise exception 'not signed in'; end if;
  for a in
    select e.* from public.entries e
    where e.day = d and e.status = 'active' and e.user_id <> uid
      and e.room_id is not distinct from p_room
      and not exists (select 1 from public.blocks bl where (bl.blocker_id = uid and bl.blocked_id = e.user_id) or (bl.blocker_id = e.user_id and bl.blocked_id = uid))
    order by e.rd desc, random()
  loop
    exit when produced >= p_n;
    continue when a.id = any (taken);
    select e.* into b from public.entries e
    where e.day = d and e.status = 'active' and e.user_id <> uid and e.id <> a.id
      and e.room_id is not distinct from p_room
      and not (e.id = any (taken))
      and not exists (select 1 from public.duels du where du.rater_id = uid and du.lo = least(a.id, e.id) and du.hi = greatest(a.id, e.id))
      and not exists (select 1 from public.blocks bl where (bl.blocker_id = uid and bl.blocked_id = e.user_id) or (bl.blocker_id = e.user_id and bl.blocked_id = uid))
    order by abs(e.mu - a.mu), random()
    limit 1;
    continue when b is null or b.id is null;
    taken := taken || a.id || b.id;
    produced := produced + 1;
    a_id := a.id; b_id := b.id; a_path := a.storage_path; b_path := b.storage_path;
    return next;
  end loop;
end $$;

create or replace function public.record_duel(p_a uuid, p_b uuid, p_winner uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  ea public.entries;
  eb public.entries;
  na record;
  nb record;
  sa double precision;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if p_winner <> p_a and p_winner <> p_b then raise exception 'winner must be one of the pair'; end if;
  select * into ea from public.entries where id = p_a for update;
  select * into eb from public.entries where id = p_b for update;
  if ea.id is null or eb.id is null then raise exception 'unknown entry'; end if;
  if ea.day <> eb.day or ea.room_id is distinct from eb.room_id then raise exception 'mismatched pair'; end if;
  if ea.status <> 'active' or eb.status <> 'active' then raise exception 'entry not active'; end if;
  if ea.user_id = uid or eb.user_id = uid then raise exception 'cannot rate your own photo'; end if;
  if not public.day_open(ea.day) then raise exception 'day is closed'; end if;
  if (select count(*) from public.duels where rater_id = uid and day = ea.day) >= 50 then raise exception 'daily duel limit reached'; end if;
  sa := case when p_winner = p_a then 1.0 else 0.0 end;
  select * into na from public.glicko_update(ea.mu, ea.rd, eb.mu, eb.rd, sa);
  select * into nb from public.glicko_update(eb.mu, eb.rd, ea.mu, ea.rd, 1.0 - sa);
  insert into public.duels (day, rater_id, a_id, b_id, winner_id) values (ea.day, uid, p_a, p_b, p_winner);
  update public.entries set mu = na.new_mu, rd = na.new_rd, duels = duels + 1, wins = wins + (sa)::int where id = p_a;
  update public.entries set mu = nb.new_mu, rd = nb.new_rd, duels = duels + 1, wins = wins + (1 - sa)::int where id = p_b;
exception when unique_violation then
  raise exception 'pair already rated';
end $$;

-- Leaderboard rows. Ranked entries (>= 6 duels) first by mu, then settling ones.
create or replace function public.leaderboard(p_day date, p_room uuid, p_scope text default 'global',
                                              p_limit integer default 100, p_offset integer default 0)
returns table (rank integer, entry_id uuid, user_id uuid, username text, display_name text,
               storage_path text, mu double precision, rd double precision, duels integer, wins integer,
               settled boolean, mine boolean, total integer)
language sql security definer set search_path = public stable as $$
  with pool as (
    select e.*, p.username, p.display_name
    from public.entries e join public.profiles p on p.id = e.user_id
    where e.day = p_day and e.status = 'active' and e.room_id is not distinct from p_room
      and (p_scope <> 'friends' or e.user_id = auth.uid()
           or exists (select 1 from public.follows f where f.follower_id = auth.uid() and f.followee_id = e.user_id))
      and not exists (select 1 from public.blocks bl where bl.blocker_id = auth.uid() and bl.blocked_id = e.user_id)
  ), ranked as (
    select *, (duels >= 6) as settled,
           row_number() over (order by (duels >= 6) desc, mu desc, duels desc, created_at) as rank,
           count(*) over () as total
    from pool
  )
  select rank::int, id, user_id, username, display_name, storage_path, mu, rd, duels, wins, settled,
         user_id = auth.uid(), total::int
  from ranked order by rank limit p_limit offset p_offset
$$;

create or replace function public.my_entry(p_day date, p_room uuid)
returns table (rank integer, entry_id uuid, storage_path text, mu double precision, rd double precision,
               duels integer, wins integer, settled boolean, total integer, status text)
language sql security definer set search_path = public stable as $$
  select l.rank, l.entry_id, l.storage_path, l.mu, l.rd, l.duels, l.wins, l.settled, l.total, e.status
  from public.leaderboard(p_day, p_room, 'global', 100000, 0) l
  join public.entries e on e.id = l.entry_id
  where l.mine
$$;

create or replace function public.my_history(p_limit integer default 60)
returns table (day date, room_id uuid, entry_id uuid, storage_path text, final_rank integer, live_rank integer,
               total integer, duels integer, wins integer, status text)
language sql security definer set search_path = public stable as $$
  select e.day, e.room_id, e.id, e.storage_path, e.final_rank,
         (select l.rank from public.leaderboard(e.day, e.room_id, 'global', 100000, 0) l where l.entry_id = e.id),
         (select count(*)::int from public.entries x where x.day = e.day and x.room_id is not distinct from e.room_id and x.status = 'active'),
         e.duels, e.wins, e.status
  from public.entries e
  where e.user_id = auth.uid() and e.status <> 'deleted'
  order by e.day desc limit p_limit
$$;

create or replace function public.my_duels_today(p_room uuid) returns integer
language sql security definer set search_path = public stable as $$
  select count(*)::int from public.duels d
  join public.entries e on e.id = d.a_id
  where d.rater_id = auth.uid() and d.day = public.arena_today() and e.room_id is not distinct from p_room
$$;

-- Rooms
create or replace function public.create_room(p_name text) returns public.rooms
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  r public.rooms;
  c text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  loop
    c := upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 6));
    exit when not exists (select 1 from public.rooms where code = c);
  end loop;
  insert into public.rooms (code, name, owner_id) values (c, p_name, uid) returning * into r;
  insert into public.room_members (room_id, user_id) values (r.id, uid);
  return r;
end $$;

create or replace function public.join_room(p_code text) returns public.rooms
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  r public.rooms;
begin
  if uid is null then raise exception 'not signed in'; end if;
  select * into r from public.rooms where code = upper(p_code);
  if r.id is null then raise exception 'no such room'; end if;
  insert into public.room_members (room_id, user_id) values (r.id, uid) on conflict do nothing;
  return r;
end $$;

create or replace function public.my_rooms()
returns table (id uuid, code text, name text, owner_id uuid, members integer)
language sql security definer set search_path = public stable as $$
  select r.id, r.code, r.name, r.owner_id, (select count(*)::int from public.room_members m where m.room_id = r.id)
  from public.rooms r join public.room_members me on me.room_id = r.id and me.user_id = auth.uid()
  order by r.created_at
$$;

create or replace function public.claim_username(p_username text) returns void
language sql security definer set search_path = public as $$
  update public.profiles set username = lower(p_username) where id = auth.uid()
$$;

-- Finalise closed days (call from pg_cron hourly).
create or replace function public.close_days() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer := 0; d record;
begin
  for d in select day from public.days where not finalized and now() > closes_at + interval '4 hours' loop
    update public.entries e set final_rank = l.rank
    from public.leaderboard(d.day, null, 'global', 100000, 0) l where l.entry_id = e.id;
    update public.entries e set final_rank = l.rank
    from public.rooms r, public.leaderboard(d.day, r.id, 'global', 100000, 0) l where l.entry_id = e.id;
    update public.days set finalized = true where day = d.day;
    n := n + 1;
  end loop;
  return n;
end $$;

-- --------------------------------------------------------------------- RLS
alter table public.profiles enable row level security;
alter table public.days enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.entries enable row level security;
alter table public.duels enable row level security;
alter table public.follows enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;

create policy "profiles readable" on public.profiles for select to authenticated using (true);
create policy "own profile update" on public.profiles for update to authenticated using (id = auth.uid());
create policy "days readable" on public.days for select to authenticated using (true);
create policy "rooms readable to members" on public.rooms for select to authenticated
  using (exists (select 1 from public.room_members m where m.room_id = id and m.user_id = auth.uid()));
create policy "members readable" on public.room_members for select to authenticated
  using (exists (select 1 from public.room_members m where m.room_id = room_id and m.user_id = auth.uid()));
create policy "active entries readable" on public.entries for select to authenticated
  using (status = 'active' or user_id = auth.uid());
create policy "own duels readable" on public.duels for select to authenticated using (rater_id = auth.uid());
create policy "follows own" on public.follows for all to authenticated using (follower_id = auth.uid()) with check (follower_id = auth.uid());
create policy "follows readable" on public.follows for select to authenticated using (true);
create policy "blocks own" on public.blocks for all to authenticated using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
create policy "reports insert" on public.reports for insert to authenticated with check (reporter_id = auth.uid());

-- Storage: private bucket, users write under their own uid, everyone signed-in can read.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('entries', 'entries', false, 1048576, array['image/webp', 'image/jpeg'])
on conflict (id) do nothing;
create policy "entries upload own" on storage.objects for insert to authenticated
  with check (bucket_id = 'entries' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "entries read" on storage.objects for select to authenticated using (bucket_id = 'entries');
create policy "entries delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'entries' and (storage.foldername(name))[1] = auth.uid()::text);
