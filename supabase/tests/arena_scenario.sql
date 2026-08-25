\set ON_ERROR_STOP on
-- Three simulated users.
insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_anonymous)
values ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated',null,now(),now(),'{}','{}',true),
       ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated',null,now(),now(),'{}','{}',true),
       ('33333333-3333-3333-3333-333333333333','00000000-0000-0000-0000-000000000000','authenticated','authenticated',null,now(),now(),'{}','{}',true)
on conflict do nothing;
select count(*) as profiles_created from public.profiles;

-- Act as user 1: submit.
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', false);
select set_config('role', 'authenticated', false);
select (public.submit_entry(null, '11111111-1111-1111-1111-111111111111/a.jpg')).mu as u1_mu;
-- Second submit today must fail.
do $$ begin
  perform public.submit_entry(null, '11111111-1111-1111-1111-111111111111/b.jpg');
  raise exception 'FAIL: duplicate submit allowed';
exception when others then
  if sqlerrm like '%already submitted%' then raise notice 'ok: duplicate submit rejected'; else raise; end if;
end $$;
-- Bad storage path must fail.
do $$ begin
  perform public.submit_entry(null, 'someone-else/x.jpg');
  raise exception 'FAIL: bad path allowed';
exception when others then
  if sqlerrm like '%bad storage path%' or sqlerrm like '%already submitted%' then raise notice 'ok: bad path rejected'; else raise; end if;
end $$;

-- User 2 submits.
select set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', false);
select (public.submit_entry(null, '22222222-2222-2222-2222-222222222222/a.jpg')).id is not null as u2_submitted;
-- User 2 must get no pairs (only own + one other = 1 candidate).
select count(*) as pairs_for_u2 from public.next_pairs(null, 10);

-- User 3 (no entry) rates: sees the pair (1,2).
select set_config('request.jwt.claims', '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', false);
select a_id is not null and b_id is not null as u3_gets_pair from public.next_pairs(null, 10);
do $$
declare p record; e1 uuid; e2 uuid; m1 double precision; m2 double precision;
begin
  select * into p from public.next_pairs(null, 1);
  select id into e1 from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
  select id into e2 from public.entries where user_id = '22222222-2222-2222-2222-222222222222';
  perform public.record_duel(p.a_id, p.b_id, e1);
  select mu into m1 from public.entries where id = e1;
  select mu into m2 from public.entries where id = e2;
  if m1 <= 1500 or m2 >= 1500 then raise exception 'FAIL: ratings did not move (% / %)', m1, m2; end if;
  raise notice 'ok: duel moved ratings to % / %', round(m1::numeric,1), round(m2::numeric,1);
  begin
    perform public.record_duel(p.a_id, p.b_id, e1);
    raise exception 'FAIL: repeated pair allowed';
  exception when others then
    if sqlerrm like '%already rated%' then raise notice 'ok: repeated pair rejected'; else raise; end if;
  end;
  if (select count(*) from public.next_pairs(null, 10)) <> 0 then raise exception 'FAIL: pair offered again'; end if;
  raise notice 'ok: rated pair not offered again';
end $$;

-- User 1 must not be able to rate their own photo.
select set_config('request.jwt.claims', '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', false);
do $$
declare e1 uuid; e2 uuid;
begin
  select id into e1 from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
  select id into e2 from public.entries where user_id = '22222222-2222-2222-2222-222222222222';
  begin
    perform public.record_duel(e1, e2, e1);
    raise exception 'FAIL: self-rating allowed';
  exception when others then
    if sqlerrm like '%own photo%' then raise notice 'ok: self-rating rejected'; else raise; end if;
  end;
end $$;

-- Leaderboard, my_entry, history, rooms.
select rank, username, round(mu::numeric,1) as mu, duels, settled, mine, total from public.leaderboard(public.arena_today(), null, 'global', 10, 0);
select rank, duels, settled, total from public.my_entry(public.arena_today(), null);
select day, live_rank, total, duels from public.my_history(10);
do $$
declare r public.rooms; j public.rooms; n integer;
begin
  select * into r from public.create_room('Family');
  if r.code !~ '^[A-Z0-9]{6}$' then raise exception 'FAIL: bad room code %', r.code; end if;
  -- user 2 joins by code (must work even though user 2 cannot see the room yet)
  perform set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', false);
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
insert into public.reports (entry_id, reporter_id) select id, '22222222-2222-2222-2222-222222222222' from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
select set_config('request.jwt.claims', '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', false);
insert into public.reports (entry_id, reporter_id) select id, '33333333-3333-3333-3333-333333333333' from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
select status as status_after_2_reports from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
select set_config('role', 'postgres', false);
insert into auth.users (id, instance_id, aud, role, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_anonymous)
values ('44444444-4444-4444-4444-444444444444','00000000-0000-0000-0000-000000000000','authenticated','authenticated',now(),now(),'{}','{}',true) on conflict do nothing;
select set_config('request.jwt.claims', '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', false);
select set_config('role', 'authenticated', false);
insert into public.reports (entry_id, reporter_id) select id, '44444444-4444-4444-4444-444444444444' from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
select status as status_after_3_reports from public.entries where user_id = '11111111-1111-1111-1111-111111111111';
-- Close days: force closes_at into the past and finalize.
select set_config('role', 'postgres', false);
update public.days set closes_at = now() - interval '5 hours';
select public.close_days() as days_closed;
select final_rank, status from public.entries order by created_at;
