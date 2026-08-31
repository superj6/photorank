-- Arena days follow US Pacific time (PST/PDT via the tz database), not UTC:
-- the global board rolls over at midnight in Los Angeles.
create or replace function public.arena_today() returns date
language sql stable as $$ select (now() at time zone 'America/Los_Angeles')::date $$;

create or replace function public.ensure_day(p_day date) returns void
language sql security definer set search_path = public as $$
  insert into public.days (day, closes_at)
  values (p_day, (p_day + 1)::timestamp at time zone 'America/Los_Angeles')
  on conflict (day) do nothing
$$;
