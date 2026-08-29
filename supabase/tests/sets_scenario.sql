\set ON_ERROR_STOP on
-- Users: 1 owner, 2 friend, 3 follower-only, 4 stranger. Run after arena_scenario or on a fresh reset.
insert into auth.users (id, instance_id, aud, role, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_anonymous)
select (rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text))::uuid,
       '00000000-0000-0000-0000-000000000000','authenticated','authenticated',now(),now(),'{}','{}',true
from generate_series(1,4) i on conflict do nothing;
create or replace function pg_temp.as_user(i int) returns void language sql as $$
  select set_config('request.jwt.claims', format('{"sub":"%s","role":"authenticated"}',
    rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text)), false);
  select set_config('role', 'authenticated', false);
$$;
create or replace function pg_temp.uid(i int) returns uuid language sql as $$
  select (rpad(i::text, 8, i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,4,i::text) || '-' || rpad(i::text,12,i::text))::uuid
$$;
select set_config('role', 'postgres', false);
update public.profiles set username = 'owner' where id = pg_temp.uid(1);
update public.profiles set username = 'friend' where id = pg_temp.uid(2);
update public.profiles set username = 'fan' where id = pg_temp.uid(3);
update public.profiles set username = 'stranger' where id = pg_temp.uid(4);
-- 1<->2 mutual, 3 follows 1 only.
insert into public.follows (follower_id, followee_id) values (pg_temp.uid(1), pg_temp.uid(2)), (pg_temp.uid(2), pg_temp.uid(1)), (pg_temp.uid(3), pg_temp.uid(1)) on conflict do nothing;

-- Owner publishes a set of 5.
select pg_temp.as_user(1);
do $$
declare s public.sets; items jsonb;
begin
  items := (select jsonb_agg(jsonb_build_object('storage_path', pg_temp.uid(1)::text || '/set/' || g || '.jpg', 'taken_at', now() - (g || ' days')::interval)) from generate_series(1,5) g);
  begin
    perform public.publish_set('too small', '[]'::jsonb);
    raise exception 'FAIL: empty set accepted';
  exception when others then
    if sqlerrm like '%3 to 50%' then raise notice 'ok: set size enforced'; else raise; end if;
  end;
  select * into s from public.publish_set('Owner''s best', items);
  if s.link_code !~ '^[A-Z0-9]{8}$' then raise exception 'FAIL: bad code'; end if;
  if (select count(*) from public.set_items where set_id = s.id) <> 5 then raise exception 'FAIL: items'; end if;
  raise notice 'ok: set published with 5 items, code %', s.link_code;
  if (select required from (select public.set_required_duels(s.id) as required) t) <> 10 then raise exception 'FAIL: required duels for 5 items should be 10'; end if;
  begin
    perform public.set_next_pairs(s.id, 3);
    raise exception 'FAIL: owner could rank own set';
  exception when others then
    if sqlerrm like '%own set%' then raise notice 'ok: owner cannot rank own set'; else raise; end if;
  end;
end $$;

-- Friend sees it; fan and stranger do not.
select pg_temp.as_user(2);
do $$ begin
  if (select count(*) from public.visible_sets()) <> 1 then raise exception 'FAIL: friend cannot see set'; end if;
  raise notice 'ok: mutual follower sees the set';
end $$;
select pg_temp.as_user(3);
do $$ begin
  if (select count(*) from public.visible_sets()) <> 0 then raise exception 'FAIL: one-way follower sees friends-only set'; end if;
  raise notice 'ok: one-way follower does not see a friends-only set';
end $$;
select pg_temp.as_user(4);
do $$
declare code text;
begin
  if (select count(*) from public.visible_sets()) <> 0 then raise exception 'FAIL: stranger sees set'; end if;
  select set_config('role', 'postgres', false) into code;
  select link_code into code from public.sets;
  perform set_config('role', 'authenticated', false);
  begin
    perform public.join_set(code);
    raise exception 'FAIL: stranger joined friends-only set by link';
  exception when others then
    if sqlerrm like '%friends-only%' then raise notice 'ok: link does not bypass friends-only'; else raise; end if;
  end;
end $$;

-- Owner opens it to links; stranger joins by code.
select pg_temp.as_user(1);
select public.set_visibility('link');
select pg_temp.as_user(4);
do $$
declare code text; sid uuid;
begin
  perform set_config('role', 'postgres', false);
  select link_code into code from public.sets;
  perform set_config('role', 'authenticated', false);
  sid := public.join_set(lower(code));
  if (select count(*) from public.visible_sets()) <> 1 then raise exception 'FAIL: link join failed'; end if;
  raise notice 'ok: link visibility lets a stranger join by code';
end $$;

-- Friend ranks the set: a full pass of 10 duels; own board + aggregate.
select pg_temp.as_user(2);
do $$
declare sid uuid; p record; n integer := 0; st record;
begin
  select set_id into sid from public.visible_sets();
  loop
    select * into p from public.set_next_pairs(sid, 1);
    exit when p.a_id is null;
    perform public.set_record_duel(sid, p.a_id, p.b_id, p.a_id);
    n := n + 1;
    exit when n > 20;
  end loop;
  if n <> 10 then raise exception 'FAIL: expected 10 duels in a pass, got %', n; end if;
  if not (select my_done from public.visible_sets() where set_id = sid) then raise exception 'FAIL: pass not marked done'; end if;
  raise notice 'ok: friend completed a pass of % duels', n;
  begin
    perform public.set_record_duel(sid, (select id from public.set_items where set_id = sid and owner_rank = 1), (select id from public.set_items where set_id = sid and owner_rank = 2), (select id from public.set_items where set_id = sid and owner_rank = 1));
    raise exception 'FAIL: rated after pass done';
  exception when others then
    if sqlerrm like '%already ranked%' then raise notice 'ok: no rating after the pass'; else raise; end if;
  end;
  if (select count(*) from public.set_board(sid, pg_temp.uid(2))) <> 5 then raise exception 'FAIL: own board'; end if;
  if (select count(*) from public.set_board(sid, null)) <> 5 then raise exception 'FAIL: aggregate board'; end if;
  if (select count(*) from public.set_board(sid, pg_temp.uid(4))) <> 0 then raise exception 'FAIL: friend can read another rater''s board'; end if;
  raise notice 'ok: rater sees own board and the aggregate, not others'' boards';
end $$;

-- Owner sees raters and each rater's board.
select pg_temp.as_user(1);
do $$
declare sid uuid; r record;
begin
  select id into sid from public.sets where owner_id = pg_temp.uid(1);
  select * into r from public.set_raters(sid) where rater_id = pg_temp.uid(2);
  if r.rater_id is null or not r.done or r.duels <> 10 then raise exception 'FAIL: raters listing'; end if;
  if (select count(*) from public.set_board(sid, pg_temp.uid(2))) <> 5 then raise exception 'FAIL: owner cannot read a friend''s board'; end if;
  raise notice 'ok: owner sees who ranked and their board (% duels)', r.duels;
  perform public.unpublish_set();
  if (select count(*) from public.sets) <> 0 then raise exception 'FAIL: unpublish'; end if;
  raise notice 'ok: unpublished (items, ratings, passes cascade)';
end $$;

-- Friend discovery.
select pg_temp.as_user(3);
select username, i_follow, follows_me from public.find_profile('OWNER');
do $$ begin
  if (select i_follow from public.find_profile('owner')) is not true then raise exception 'FAIL: find_profile'; end if;
  if (select count(*) from public.my_friends()) <> 1 then raise exception 'FAIL: my_friends'; end if;
  raise notice 'ok: friend lookup and list';
end $$;
