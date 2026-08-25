-- Once you have rated your set, today's board stays open even if more
-- people enter later (which would raise required_duels). The set is rated
-- once: no more duels after it is complete.
alter table public.entries add column if not exists set_done_at timestamptz;

create or replace function public.arena_status(p_room uuid)
returns table (has_entry boolean, duels_today integer, required integer, unlocked boolean, others integer)
language sql security definer set search_path = public stable as $$
  with me as (
    select e.id as entry_id, e.set_done_at
    from public.entries e
    where e.day = public.arena_today() and e.user_id = auth.uid() and e.room_id is not distinct from p_room and e.status = 'active'
  ), stats as (
    select (select count(*)::int from public.duels d join public.entries a on a.id = d.a_id
             where d.rater_id = auth.uid() and d.day = public.arena_today() and a.room_id is not distinct from p_room) as duels_today,
           public.required_duels(p_room) as required,
           (select count(*)::int from public.entries e where e.day = public.arena_today() and e.status = 'active'
             and e.user_id <> auth.uid() and e.room_id is not distinct from p_room) as others
  )
  select (select count(*) from me) > 0,
         s.duels_today,
         case when (select set_done_at from me) is not null then s.duels_today else s.required end,
         (select count(*) from me) > 0 and ((select set_done_at from me) is not null or s.duels_today >= s.required),
         s.others
  from stats s
$$;

create or replace function public.record_duel(p_a uuid, p_b uuid, p_winner uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  ea public.entries;
  eb public.entries;
  mine public.entries;
  na record;
  nb record;
  sa double precision;
  done_after integer;
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
  select * into mine from public.entries m where m.day = ea.day and m.user_id = uid and m.room_id is not distinct from ea.room_id and m.status = 'active';
  if mine.id is null then raise exception 'enter a photo first'; end if;
  if mine.set_done_at is not null then raise exception 'you have rated your set for today'; end if;
  sa := case when p_winner = p_a then 1.0 else 0.0 end;
  select * into na from public.glicko_update(ea.mu, ea.rd, eb.mu, eb.rd, sa);
  select * into nb from public.glicko_update(eb.mu, eb.rd, ea.mu, ea.rd, 1.0 - sa);
  insert into public.duels (day, rater_id, a_id, b_id, winner_id) values (ea.day, uid, p_a, p_b, p_winner);
  update public.entries set mu = na.new_mu, rd = na.new_rd, duels = duels + 1, wins = wins + (sa)::int where id = p_a;
  update public.entries set mu = nb.new_mu, rd = nb.new_rd, duels = duels + 1, wins = wins + (1 - sa)::int where id = p_b;
  select count(*)::int into done_after from public.duels d join public.entries a on a.id = d.a_id
    where d.rater_id = uid and d.day = ea.day and a.room_id is not distinct from ea.room_id;
  if done_after >= public.required_duels(ea.room_id) then
    update public.entries set set_done_at = now() where id = mine.id;
  end if;
exception when unique_violation then
  raise exception 'pair already rated';
end $$;
