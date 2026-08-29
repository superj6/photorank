-- Published sets: a player publishes their Top N so friends can see it and
-- rank it. Each friend rates the set once (a pass of duels) and gets their
-- own board; every duel also feeds a pooled aggregate board.
-- Friends = mutual follows. Visibility: friends | link | public.

create table if not exists public.sets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles (id) on delete cascade,
  title text not null default 'My top photos',
  visibility text not null default 'friends' check (visibility in ('friends', 'link', 'public')),
  link_code text unique not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.set_items (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.sets (id) on delete cascade,
  storage_path text not null,
  owner_rank integer not null,            -- 1 = the owner's favourite
  taken_at timestamptz,
  mu double precision not null default 1500,   -- pooled (aggregate) rating
  rd double precision not null default 350,
  duels integer not null default 0,
  wins integer not null default 0,
  unique (set_id, owner_rank)
);

-- One rater's private rating of one item.
create table if not exists public.set_ratings (
  set_id uuid not null references public.sets (id) on delete cascade,
  rater_id uuid not null references public.profiles (id) on delete cascade,
  item_id uuid not null references public.set_items (id) on delete cascade,
  mu double precision not null default 1500,
  rd double precision not null default 350,
  duels integer not null default 0,
  wins integer not null default 0,
  primary key (set_id, rater_id, item_id)
);

create table if not exists public.set_duels (
  id bigserial primary key,
  set_id uuid not null references public.sets (id) on delete cascade,
  rater_id uuid not null references public.profiles (id) on delete cascade,
  a_id uuid not null references public.set_items (id) on delete cascade,
  b_id uuid not null references public.set_items (id) on delete cascade,
  winner_id uuid not null references public.set_items (id) on delete cascade,
  lo uuid generated always as (least(a_id, b_id)) stored,
  hi uuid generated always as (greatest(a_id, b_id)) stored,
  created_at timestamptz not null default now(),
  unique (set_id, rater_id, lo, hi)
);

-- A rater's pass over a set: done when required duels are reached.
create table if not exists public.set_passes (
  set_id uuid not null references public.sets (id) on delete cascade,
  rater_id uuid not null references public.profiles (id) on delete cascade,
  started_at timestamptz not null default now(),
  done_at timestamptz,
  primary key (set_id, rater_id)
);

-- Sets joined by link code (grants access regardless of friendship).
create table if not exists public.set_access (
  set_id uuid not null references public.sets (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (set_id, user_id)
);

alter table public.sets enable row level security;
alter table public.set_items enable row level security;
alter table public.set_ratings enable row level security;
alter table public.set_duels enable row level security;
alter table public.set_passes enable row level security;
alter table public.set_access enable row level security;

-- ------------------------------------------------------------- helpers
create or replace function public.are_friends(p_a uuid, p_b uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select p_a is not null and p_b is not null and p_a <> p_b
     and exists (select 1 from public.follows where follower_id = p_a and followee_id = p_b)
     and exists (select 1 from public.follows where follower_id = p_b and followee_id = p_a)
$$;

create or replace function public.can_view_set(p_set uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.sets s
    where s.id = p_set
      and (s.owner_id = auth.uid()
           or s.visibility = 'public'
           or exists (select 1 from public.set_access a where a.set_id = s.id and a.user_id = auth.uid())
           or (s.visibility in ('friends', 'link') and public.are_friends(auth.uid(), s.owner_id)))
  )
$$;

create policy "sets visible" on public.sets for select to authenticated using (public.can_view_set(id));
create policy "items visible" on public.set_items for select to authenticated using (public.can_view_set(set_id));
create policy "own ratings" on public.set_ratings for select to authenticated
  using (rater_id = auth.uid() or exists (select 1 from public.sets s where s.id = set_id and s.owner_id = auth.uid()));
create policy "own duels" on public.set_duels for select to authenticated using (rater_id = auth.uid());
create policy "passes visible" on public.set_passes for select to authenticated
  using (rater_id = auth.uid() or exists (select 1 from public.sets s where s.id = set_id and s.owner_id = auth.uid()));
create policy "own access" on public.set_access for select to authenticated using (user_id = auth.uid());

-- ------------------------------------------------------------- publish
-- Replaces the owner's set entirely. p_items: [{"storage_path": "...", "taken_at": "..."}] in rank order.
create or replace function public.publish_set(p_title text, p_items jsonb, p_visibility text default 'friends') returns public.sets
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  s public.sets;
  item jsonb;
  r integer := 0;
  code text;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if (select username from public.profiles where id = uid) is null then raise exception 'claim a username first'; end if;
  if jsonb_array_length(p_items) < 3 or jsonb_array_length(p_items) > 50 then raise exception 'a set has 3 to 50 photos'; end if;
  if p_visibility not in ('friends', 'link', 'public') then raise exception 'bad visibility'; end if;
  for item in select * from jsonb_array_elements(p_items) loop
    if (item->>'storage_path') not like uid::text || '/%' then raise exception 'bad storage path'; end if;
  end loop;
  loop
    code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    exit when not exists (select 1 from public.sets where link_code = code);
  end loop;
  delete from public.sets where owner_id = uid;   -- cascades items, ratings, duels, passes, access
  insert into public.sets (owner_id, title, visibility, link_code)
  values (uid, coalesce(nullif(trim(p_title), ''), 'My top photos'), p_visibility, code)
  returning * into s;
  for item in select * from jsonb_array_elements(p_items) loop
    r := r + 1;
    insert into public.set_items (set_id, storage_path, owner_rank, taken_at)
    values (s.id, item->>'storage_path', r, nullif(item->>'taken_at', '')::timestamptz);
  end loop;
  return s;
end $$;

create or replace function public.unpublish_set() returns void
language sql security definer set search_path = public as $$
  delete from public.sets where owner_id = auth.uid()
$$;

create or replace function public.set_visibility(p_visibility text) returns void
language sql security definer set search_path = public as $$
  update public.sets set visibility = p_visibility, updated_at = now()
  where owner_id = auth.uid() and p_visibility in ('friends', 'link', 'public')
$$;

create or replace function public.join_set(p_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare s public.sets;
begin
  select * into s from public.sets where link_code = upper(p_code);
  if s.id is null then raise exception 'no such set'; end if;
  if s.visibility = 'friends' and not public.are_friends(auth.uid(), s.owner_id) and s.owner_id <> auth.uid() then
    raise exception 'this set is friends-only';
  end if;
  insert into public.set_access (set_id, user_id) values (s.id, auth.uid()) on conflict do nothing;
  return s.id;
end $$;

-- ------------------------------------------------------------- browsing
create or replace function public.visible_sets()
returns table (set_id uuid, owner_id uuid, owner_username text, title text, visibility text, link_code text,
               items integer, updated_at timestamptz, my_done boolean, my_duels integer, raters integer)
language sql security definer set search_path = public stable as $$
  select s.id, s.owner_id, p.username, s.title, s.visibility,
         case when s.owner_id = auth.uid() then s.link_code else null end,
         (select count(*)::int from public.set_items i where i.set_id = s.id),
         s.updated_at,
         exists (select 1 from public.set_passes sp where sp.set_id = s.id and sp.rater_id = auth.uid() and sp.done_at is not null),
         (select count(*)::int from public.set_duels d where d.set_id = s.id and d.rater_id = auth.uid()),
         (select count(*)::int from public.set_passes sp where sp.set_id = s.id and sp.done_at is not null)
  from public.sets s join public.profiles p on p.id = s.owner_id
  where public.can_view_set(s.id)
  order by (s.owner_id = auth.uid()) desc, s.updated_at desc
$$;

create or replace function public.set_required_duels(p_set uuid) returns integer
language sql security definer set search_path = public stable as $$
  select least(15, n * (n - 1) / 2) from (select count(*)::int as n from public.set_items where set_id = p_set) t
$$;

-- Pairs for the caller's pass: items of similar (caller's own) rating, never a pair they rated.
create or replace function public.set_next_pairs(p_set uuid, p_n integer default 10)
returns table (a_id uuid, b_id uuid, a_path text, b_path text)
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  a record; b record;
  taken uuid[] := '{}';
  produced integer := 0;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if not public.can_view_set(p_set) then raise exception 'no access to this set'; end if;
  if (select owner_id from public.sets where id = p_set) = uid then raise exception 'you cannot rank your own set'; end if;
  insert into public.set_passes (set_id, rater_id) values (p_set, uid) on conflict do nothing;
  for a in
    select i.id, i.storage_path, coalesce(r.mu, 1500) as mu, coalesce(r.rd, 350) as rd
    from public.set_items i left join public.set_ratings r on r.item_id = i.id and r.rater_id = uid
    where i.set_id = p_set order by coalesce(r.rd, 350) desc, random()
  loop
    exit when produced >= p_n;
    continue when a.id = any (taken);
    select i.id, i.storage_path into b
    from public.set_items i left join public.set_ratings r on r.item_id = i.id and r.rater_id = uid
    where i.set_id = p_set and i.id <> a.id and not (i.id = any (taken))
      and not exists (select 1 from public.set_duels d where d.set_id = p_set and d.rater_id = uid
                      and d.lo = least(a.id, i.id) and d.hi = greatest(a.id, i.id))
    order by abs(coalesce(r.mu, 1500) - a.mu), random() limit 1;
    continue when b is null or b.id is null;
    taken := taken || a.id || b.id;
    produced := produced + 1;
    a_id := a.id; b_id := b.id; a_path := a.storage_path; b_path := b.storage_path;
    return next;
  end loop;
end $$;

create or replace function public.set_record_duel(p_set uuid, p_a uuid, p_b uuid, p_winner uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  ra public.set_ratings; rb public.set_ratings;
  ia public.set_items; ib public.set_items;
  na record; nb record; pa record; pb record;
  sa double precision;
  done integer;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if p_winner <> p_a and p_winner <> p_b then raise exception 'winner must be one of the pair'; end if;
  if not public.can_view_set(p_set) then raise exception 'no access to this set'; end if;
  if (select owner_id from public.sets where id = p_set) = uid then raise exception 'you cannot rank your own set'; end if;
  if (select done_at from public.set_passes where set_id = p_set and rater_id = uid) is not null then
    raise exception 'you have already ranked this set';
  end if;
  select * into ia from public.set_items where id = p_a and set_id = p_set for update;
  select * into ib from public.set_items where id = p_b and set_id = p_set for update;
  if ia.id is null or ib.id is null then raise exception 'unknown item'; end if;
  insert into public.set_ratings (set_id, rater_id, item_id) values (p_set, uid, p_a) on conflict do nothing;
  insert into public.set_ratings (set_id, rater_id, item_id) values (p_set, uid, p_b) on conflict do nothing;
  select * into ra from public.set_ratings where set_id = p_set and rater_id = uid and item_id = p_a for update;
  select * into rb from public.set_ratings where set_id = p_set and rater_id = uid and item_id = p_b for update;
  sa := case when p_winner = p_a then 1.0 else 0.0 end;
  -- The rater's own board...
  select * into na from public.glicko_update(ra.mu, ra.rd, rb.mu, rb.rd, sa);
  select * into nb from public.glicko_update(rb.mu, rb.rd, ra.mu, ra.rd, 1.0 - sa);
  update public.set_ratings set mu = na.new_mu, rd = na.new_rd, duels = duels + 1, wins = wins + sa::int where set_id = p_set and rater_id = uid and item_id = p_a;
  update public.set_ratings set mu = nb.new_mu, rd = nb.new_rd, duels = duels + 1, wins = wins + (1 - sa)::int where set_id = p_set and rater_id = uid and item_id = p_b;
  -- ...and the pooled aggregate.
  select * into pa from public.glicko_update(ia.mu, ia.rd, ib.mu, ib.rd, sa);
  select * into pb from public.glicko_update(ib.mu, ib.rd, ia.mu, ia.rd, 1.0 - sa);
  update public.set_items set mu = pa.new_mu, rd = pa.new_rd, duels = duels + 1, wins = wins + sa::int where id = p_a;
  update public.set_items set mu = pb.new_mu, rd = pb.new_rd, duels = duels + 1, wins = wins + (1 - sa)::int where id = p_b;
  insert into public.set_duels (set_id, rater_id, a_id, b_id, winner_id) values (p_set, uid, p_a, p_b, p_winner);
  select count(*)::int into done from public.set_duels where set_id = p_set and rater_id = uid;
  if done >= public.set_required_duels(p_set) then
    update public.set_passes set done_at = now() where set_id = p_set and rater_id = uid and done_at is null;
  end if;
exception when unique_violation then
  raise exception 'pair already rated';
end $$;

-- A board: one rater's ordering (p_rater) or the pooled aggregate (null).
-- The owner may read any rater's board; a rater may read their own; the
-- aggregate is readable by anyone who can view the set.
create or replace function public.set_board(p_set uuid, p_rater uuid default null)
returns table (rank integer, item_id uuid, storage_path text, owner_rank integer, mu double precision, duels integer, wins integer)
language sql security definer set search_path = public stable as $$
  with allowed as (
    select public.can_view_set(p_set)
       and (p_rater is null or p_rater = auth.uid() or (select owner_id from public.sets where id = p_set) = auth.uid()) as ok
  ), rows as (
    select i.id, i.storage_path, i.owner_rank,
           case when p_rater is null then i.mu else coalesce(r.mu, 1500) end as mu,
           case when p_rater is null then i.duels else coalesce(r.duels, 0) end as duels,
           case when p_rater is null then i.wins else coalesce(r.wins, 0) end as wins
    from public.set_items i
    left join public.set_ratings r on p_rater is not null and r.item_id = i.id and r.rater_id = p_rater
    where i.set_id = p_set and (select ok from allowed)
  )
  select row_number() over (order by mu desc, duels desc, owner_rank)::int, id, storage_path, owner_rank, mu, duels, wins
  from rows order by 1
$$;

-- Who has ranked the caller's set, and how far along they are.
create or replace function public.set_raters(p_set uuid)
returns table (rater_id uuid, username text, duels integer, done boolean, started_at timestamptz)
language sql security definer set search_path = public stable as $$
  select sp.rater_id, p.username,
         (select count(*)::int from public.set_duels d where d.set_id = p_set and d.rater_id = sp.rater_id),
         sp.done_at is not null, sp.started_at
  from public.set_passes sp join public.profiles p on p.id = sp.rater_id
  where sp.set_id = p_set and (select owner_id from public.sets where id = p_set) = auth.uid()
  order by sp.done_at desc nulls last, sp.started_at desc
$$;

-- ------------------------------------------------------------- friends
create or replace function public.find_profile(p_username text)
returns table (id uuid, username text, i_follow boolean, follows_me boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.username,
         exists (select 1 from public.follows f where f.follower_id = auth.uid() and f.followee_id = p.id),
         exists (select 1 from public.follows f where f.follower_id = p.id and f.followee_id = auth.uid())
  from public.profiles p
  where p.username = lower(trim(p_username)) and p.id <> auth.uid() and not p.banned
$$;

create or replace function public.my_friends()
returns table (id uuid, username text, i_follow boolean, follows_me boolean, has_set boolean)
language sql security definer set search_path = public stable as $$
  select p.id, p.username,
         exists (select 1 from public.follows f where f.follower_id = auth.uid() and f.followee_id = p.id),
         exists (select 1 from public.follows f where f.follower_id = p.id and f.followee_id = auth.uid()),
         exists (select 1 from public.sets s where s.owner_id = p.id)
  from public.profiles p
  where p.id <> auth.uid() and not p.banned
    and (exists (select 1 from public.follows f where f.follower_id = auth.uid() and f.followee_id = p.id)
      or exists (select 1 from public.follows f where f.follower_id = p.id and f.followee_id = auth.uid()))
  order by p.username
$$;

grant select on public.sets, public.set_items, public.set_ratings, public.set_duels, public.set_passes, public.set_access to authenticated;
grant execute on all functions in schema public to authenticated;
revoke execute on function public.close_days() from authenticated;
