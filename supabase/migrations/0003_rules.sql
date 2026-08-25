-- Rules: the photo must be from today; after uploading you rate ONE set,
-- and only then can you see today's board; past days are public and final
-- at 00:00 UTC (no grace period).

alter table public.entries add column if not exists taken_at timestamptz;

create or replace function public.day_open(p_day date) returns boolean
language sql stable as $$
  select now() < (select closes_at from public.days where day = p_day)
$$;

drop function if exists public.submit_entry(uuid, text);
create or replace function public.submit_entry(p_room uuid, p_storage_path text, p_taken_at timestamptz) returns public.entries
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
  insert into public.profiles (id) values (uid) on conflict do nothing;
  -- "From today": within the last 36 hours (covers any local timezone), not in the future.
  if p_taken_at is null or p_taken_at < now() - interval '36 hours' or p_taken_at > now() + interval '2 hours' then
    raise exception 'photo must be taken today';
  end if;
  perform public.ensure_day(d);
  insert into public.entries (day, user_id, room_id, storage_path, taken_at)
  values (d, uid, p_room, p_storage_path, p_taken_at)
  returning * into row;
  return row;
exception when unique_violation then
  raise exception 'already submitted today';
end $$;

-- The set you rate right after uploading: up to 10 duels, fewer in tiny pools.
create or replace function public.required_duels(p_room uuid) returns integer
language sql security definer set search_path = public stable as $$
  with others as (
    select count(*)::int as n from public.entries e
    where e.day = public.arena_today() and e.status = 'active' and e.user_id <> auth.uid()
      and e.room_id is not distinct from p_room
  )
  select least(10, n * (n - 1) / 2) from others
$$;

create or replace function public.arena_status(p_room uuid)
returns table (has_entry boolean, duels_today integer, required integer, unlocked boolean, others integer)
language sql security definer set search_path = public stable as $$
  with me as (
    select exists (select 1 from public.entries e where e.day = public.arena_today() and e.user_id = auth.uid()
                   and e.room_id is not distinct from p_room and e.status = 'active') as has_entry,
           (select count(*)::int from public.duels d join public.entries a on a.id = d.a_id
             where d.rater_id = auth.uid() and d.day = public.arena_today() and a.room_id is not distinct from p_room) as duels_today,
           public.required_duels(p_room) as required,
           (select count(*)::int from public.entries e where e.day = public.arena_today() and e.status = 'active'
             and e.user_id <> auth.uid() and e.room_id is not distinct from p_room) as others
  )
  select has_entry, duels_today, required, has_entry and duels_today >= required, others from me
$$;

create or replace function public.can_view_today(p_room uuid) returns boolean
language sql security definer set search_path = public stable as $$
  select coalesce((select unlocked from public.arena_status(p_room)), false)
$$;

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
  if not exists (select 1 from public.entries m where m.day = ea.day and m.user_id = uid and m.room_id is not distinct from ea.room_id and m.status = 'active') then
    raise exception 'enter a photo first';
  end if;
  if (select count(*) from public.duels d join public.entries a on a.id = d.a_id
      where d.rater_id = uid and d.day = ea.day and a.room_id is not distinct from ea.room_id) >= 10 then
    raise exception 'you have rated your set for today';
  end if;
  sa := case when p_winner = p_a then 1.0 else 0.0 end;
  select * into na from public.glicko_update(ea.mu, ea.rd, eb.mu, eb.rd, sa);
  select * into nb from public.glicko_update(eb.mu, eb.rd, ea.mu, ea.rd, 1.0 - sa);
  insert into public.duels (day, rater_id, a_id, b_id, winner_id) values (ea.day, uid, p_a, p_b, p_winner);
  update public.entries set mu = na.new_mu, rd = na.new_rd, duels = duels + 1, wins = wins + (sa)::int where id = p_a;
  update public.entries set mu = nb.new_mu, rd = nb.new_rd, duels = duels + 1, wins = wins + (1 - sa)::int where id = p_b;
exception when unique_violation then
  raise exception 'pair already rated';
end $$;

-- Today's board is hidden until the caller has entered and rated their set;
-- past days are public. (close_days runs as postgres on past days only.)
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
      and (p_day < public.arena_today() or auth.uid() is null or public.can_view_today(p_room))
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

-- Past days with a board (public), newest first, with the caller's finish.
create or replace function public.arena_days(p_room uuid, p_limit integer default 60)
returns table (day date, entries integer, finalized boolean, my_final_rank integer, my_storage_path text)
language sql security definer set search_path = public stable as $$
  select d.day,
         (select count(*)::int from public.entries e where e.day = d.day and e.room_id is not distinct from p_room and e.status = 'active'),
         d.finalized,
         (select e.final_rank from public.entries e where e.day = d.day and e.room_id is not distinct from p_room and e.user_id = auth.uid()),
         (select e.storage_path from public.entries e where e.day = d.day and e.room_id is not distinct from p_room and e.user_id = auth.uid())
  from public.days d
  where d.day < public.arena_today()
    and exists (select 1 from public.entries e where e.day = d.day and e.room_id is not distinct from p_room and e.status = 'active')
  order by d.day desc limit p_limit
$$;

drop function if exists public.my_duels_today(uuid);
grant execute on all functions in schema public to authenticated;
revoke execute on function public.close_days() from authenticated;

-- Finalise at 00:00 UTC exactly (no grace).
create or replace function public.close_days() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer := 0; d record;
begin
  for d in select day from public.days where not finalized and now() > closes_at loop
    update public.entries e set final_rank = l.rank
    from public.leaderboard(d.day, null, 'global', 100000, 0) l where l.entry_id = e.id;
    update public.entries e set final_rank = l.rank
    from public.rooms r, public.leaderboard(d.day, r.id, 'global', 100000, 0) l where l.entry_id = e.id;
    update public.days set finalized = true where day = d.day;
    n := n + 1;
  end loop;
  return n;
end $$;

-- Self-heal a missing profile row (the auth trigger is the normal path).
create or replace function public.ensure_profile() returns void
language sql security definer set search_path = public as $$
  insert into public.profiles (id) select auth.uid() where auth.uid() is not null on conflict do nothing
$$;
grant execute on function public.ensure_profile() to authenticated;
