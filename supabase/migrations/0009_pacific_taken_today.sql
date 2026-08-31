-- "Taken today" now means the current Pacific arena day (2h clock-skew
-- slack), replacing the old any-timezone 36-hour window: yesterday's photo
-- can no longer enter today's board.
create or replace function public.submit_entry(p_room uuid, p_storage_path text, p_taken_at timestamptz) returns public.entries
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  d date := public.arena_today();
  day_start timestamptz := d::timestamp at time zone 'America/Los_Angeles';
  row public.entries;
begin
  if uid is null then raise exception 'not signed in'; end if;
  if (select banned from public.profiles where id = uid) then raise exception 'banned'; end if;
  if p_room is not null and not exists (select 1 from public.room_members where room_id = p_room and user_id = uid) then
    raise exception 'not a member of this room';
  end if;
  if p_storage_path not like uid::text || '/%' then raise exception 'bad storage path'; end if;
  insert into public.profiles (id) values (uid) on conflict do nothing;
  if p_taken_at is null or p_taken_at < day_start - interval '2 hours' or p_taken_at > now() + interval '2 hours' then
    raise exception 'photo must be taken today (Pacific time)';
  end if;
  perform public.ensure_day(d);
  insert into public.entries (day, user_id, room_id, storage_path, taken_at)
  values (d, uid, p_room, p_storage_path, p_taken_at)
  returning * into row;
  return row;
exception when unique_violation then
  raise exception 'already submitted today';
end $$;
