\set ON_ERROR_STOP on
-- Simulated users 1..3. Run on a fresh `supabase db reset`.
insert into auth.users (id, instance_id, aud, role, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_anonymous)
select (rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text))::uuid,
       '00000000-0000-0000-0000-000000000000','authenticated','authenticated',now(),now(),'{}','{}',true
from generate_series(1,4) i on conflict do nothing;
select count(*) as profiles_created from public.profiles;

create or replace function pg_temp.as_user(i int) returns void language sql as $$
  select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}',
    rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text)), false);
  select set_config('role', 'authenticated', false);
$$;
create or replace function pg_temp.uid(i int) returns uuid language sql as $$
  select (rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text))::uuid
$$;

-- User 1 submits; photo must be from today.
select pg_temp.as_user(1);
do $$ begin
  perform public.submit_entry(null, pg_temp.uid(1)::text || '/old.jpg', now() - interval '3 days');
  raise exception 'FAIL: old photo accepted';
exception when others then
  if sqlerrm like '%taken today%' then raise notice 'ok: old photo rejected'; else raise; end if;
end $$;
select (public.submit_entry(null, pg_temp.uid(1)::text || '/a.jpg', now() - interval '2 hours')).mu as u1_mu;
do $$ begin
  perform public.submit_entry(null, pg_temp.uid(1)::text || '/b.jpg', now());
  raise exception 'FAIL: duplicate submit allowed';
exception when others then
  if sqlerrm like '%already submitted%' then raise notice 'ok: duplicate submit rejected'; else raise; end if;
end $$;
do $$ begin
  perform public.submit_entry(null, 'someone-else/x.jpg', now());
  raise exception 'FAIL: bad path allowed';
exception when others then
  if sqlerrm like '%bad storage path%' or sqlerrm like '%already submitted%' then raise notice 'ok: bad path rejected'; else raise; end if;
end $$;
-- Alone on the board there is nothing to rate: unlocked with required = 0.
select has_entry, required, unlocked from public.arena_status(null);

-- Users 2 and 3 submit.
select pg_temp.as_user(2);
select (public.submit_entry(null, pg_temp.uid(2)::text || '/a.jpg', now())).id is not null as u2_submitted;
select pg_temp.as_user(3);
select (public.submit_entry(null, pg_temp.uid(3)::text || '/a.jpg', now())).id is not null as u3_submitted;

-- Now user 1 has a set to rate and cannot see today's board until done.
select pg_temp.as_user(1);
do $$ begin
  if (select count(*) from public.leaderboard(public.arena_today(), null)) <> 0 then raise exception 'FAIL: board visible before rating'; end if;
  raise notice 'ok: board hidden before rating the set';
end $$;

-- User 4 has no entry: cannot rate, cannot see.
select pg_temp.as_user(4);
do $$
declare e1 uuid; e2 uuid;
begin
  select id into e1 from public.entries where user_id = pg_temp.uid(1);
  select id into e2 from public.entries where user_id = pg_temp.uid(2);
  begin
    perform public.record_duel(e1, e2, e1);
    raise exception 'FAIL: rating without an entry allowed';
  exception when others then
    if sqlerrm like '%enter a photo first%' then raise notice 'ok: must enter before rating'; else raise; end if;
  end;
  if (select count(*) from public.leaderboard(public.arena_today(), null)) <> 0 then raise exception 'FAIL: board visible without entry'; end if;
  raise notice 'ok: board hidden without entry';
end $$;

-- User 3 rates their set: 2 others -> 1 pair required.
select pg_temp.as_user(3);
select has_entry, duels_today, required, unlocked, others from public.arena_status(null);
do $$
declare p record; s record; m1 double precision;
begin
  select * into s from public.arena_status(null);
  if s.required <> 1 or s.unlocked then raise exception 'FAIL: expected required=1, locked (got % / %)', s.required, s.unlocked; end if;
  select * into p from public.next_pairs(null, 10);
  if p.a_id is null then raise exception 'FAIL: no pair offered'; end if;
  perform public.record_duel(p.a_id, p.b_id, p.a_id);
  select mu into m1 from public.entries where id = p.a_id;
  if m1 <= 1500 then raise exception 'FAIL: rating did not move'; end if;
  raise notice 'ok: duel moved winner to %', round(m1::numeric, 1);
  begin
    perform public.record_duel(p.a_id, p.b_id, p.a_id);
    raise exception 'FAIL: repeated pair allowed';
  exception when others then
    if sqlerrm like '%already rated%' then raise notice 'ok: repeated pair rejected'; else raise; end if;
  end;
  select * into s from public.arena_status(null);
  if not s.unlocked then raise exception 'FAIL: still locked after rating the set'; end if;
  if (select count(*) from public.leaderboard(public.arena_today(), null)) <> 3 then raise exception 'FAIL: board not visible after rating'; end if;
  raise notice 'ok: board unlocked after rating the set (% rows)', (select count(*) from public.leaderboard(public.arena_today(), null));
  if (select count(*) from public.next_pairs(null, 10)) <> 0 then raise exception 'FAIL: rated pair offered again'; end if;
  raise notice 'ok: rated pair not offered again';
end $$;
select rank, duels, settled, total from public.my_entry(public.arena_today(), null);

-- Self-rating rejected.
select pg_temp.as_user(1);
do $$
declare e1 uuid; e2 uuid;
begin
  select id into e1 from public.entries where user_id = pg_temp.uid(1);
  select id into e2 from public.entries where user_id = pg_temp.uid(2);
  begin
    perform public.record_duel(e1, e2, e1);
    raise exception 'FAIL: self-rating allowed';
  exception when others then
    if sqlerrm like '%own photo%' then raise notice 'ok: self-rating rejected'; else raise; end if;
  end;
end $$;

-- Rooms: create, join by code, bogus code.
do $$
declare r public.rooms; j public.rooms; n integer;
begin
  select * into r from public.create_room('Family');
  if r.code !~ '^[A-Z0-9]{6}$' then raise exception 'FAIL: bad room code %', r.code; end if;
  perform pg_temp.as_user(2);
  select * into j from public.join_room(lower(r.code));
  if j.id <> r.id then raise exception 'FAIL: join returned wrong room'; end if;
  select members into n from public.my_rooms() where id = r.id;
  if n <> 2 then raise exception 'FAIL: expected 2 members, got %', n; end if;
  raise notice 'ok: room created and joined by code (% members)', n;
  begin
    perform public.join_room('ZZZZZZ');
    raise exception 'FAIL: bogus code joined';
  exception when others then
    if sqlerrm like '%no such room%' then raise notice 'ok: bogus code rejected'; else raise; end if;
  end;
end $$;

-- Reports: three reports hide an entry.
select pg_temp.as_user(2);
insert into public.reports (entry_id, reporter_id) select id, pg_temp.uid(2) from public.entries where user_id = pg_temp.uid(1);
select pg_temp.as_user(3);
insert into public.reports (entry_id, reporter_id) select id, pg_temp.uid(3) from public.entries where user_id = pg_temp.uid(1);
select set_config('role', 'postgres', false);
select status as status_after_2_reports from public.entries where user_id = pg_temp.uid(1);
select pg_temp.as_user(4);
insert into public.reports (entry_id, reporter_id) select id, pg_temp.uid(4) from public.entries where user_id = pg_temp.uid(1);
select set_config('role', 'postgres', false);
select status as status_after_3_reports from public.entries where user_id = pg_temp.uid(1);

-- Day closes at 00:00 UTC: rating is rejected, ranks freeze, past board is public.
update public.days set closes_at = now() - interval '1 minute';
select pg_temp.as_user(3);
do $$
declare e2 uuid; e3 uuid;
begin
  select id into e2 from public.entries where user_id = pg_temp.uid(2);
  select id into e3 from public.entries where user_id = pg_temp.uid(3);
  begin
    perform public.record_duel(e2, e3, e2);
    raise exception 'FAIL: rating after close allowed';
  exception when others then
    if sqlerrm like '%day is closed%' or sqlerrm like '%own photo%' then raise notice 'ok: closed day rejects rating'; else raise; end if;
  end;
end $$;
select set_config('role', 'postgres', false);
select public.close_days() as days_closed;
select final_rank is not null as finalized_ranks from public.entries where status = 'active' limit 1;
-- A finished day from yesterday (inserted directly) is public to everyone.
insert into public.days (day, closes_at, finalized) values (public.arena_today() - 1, (public.arena_today())::timestamp at time zone 'utc', true);
insert into public.entries (day, user_id, storage_path, mu, rd, duels, wins, final_rank, taken_at)
values (public.arena_today() - 1, pg_temp.uid(2), pg_temp.uid(2)::text || '/y.jpg', 1700, 60, 8, 6, 1, now() - interval '1 day'),
       (public.arena_today() - 1, pg_temp.uid(3), pg_temp.uid(3)::text || '/y.jpg', 1400, 60, 8, 2, 2, now() - interval '1 day');
select pg_temp.as_user(4);
select day, entries, finalized, my_final_rank from public.arena_days(null);
do $$ begin
  if (select count(*) from public.leaderboard(public.arena_today() - 1, null)) <> 2 then raise exception 'FAIL: past board not public'; end if;
  if (select count(*) from public.arena_days(null)) <> 1 then raise exception 'FAIL: arena_days wrong'; end if;
  raise notice 'ok: past board public to a user with no entry';
end $$;
select pg_temp.as_user(2);
select day, final_rank, total from public.my_history(10);
