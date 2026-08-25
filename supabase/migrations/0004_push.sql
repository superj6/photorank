-- Result pushes: device tokens, an outbox filled when a day closes, and an
-- edge function (supabase/functions/send-push) that delivers via FCM.

create table if not exists public.device_tokens (
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);
alter table public.device_tokens enable row level security;
create policy "own tokens" on public.device_tokens for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.register_device_token(p_token text, p_platform text) returns void
language sql security definer set search_path = public as $$
  insert into public.device_tokens (user_id, token, platform)
  select auth.uid(), p_token, coalesce(p_platform, 'android') where auth.uid() is not null
  on conflict (user_id, token) do update set platform = excluded.platform, updated_at = now()
$$;
grant execute on function public.register_device_token(text, text) to authenticated;

create table if not exists public.notification_outbox (
  id bigserial primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}',
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  error text
);
alter table public.notification_outbox enable row level security;  -- service role only
create index if not exists outbox_unsent_idx on public.notification_outbox (sent_at) where sent_at is null;

-- Finalise closed days and queue "you finished #N" for every entrant.
create or replace function public.close_days() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer := 0; d record;
begin
  for d in select day from public.days where not finalized and now() > closes_at loop
    update public.entries e set final_rank = l.rank
    from public.leaderboard(d.day, null, 'global', 100000, 0) l where l.entry_id = e.id;
    update public.entries e set final_rank = l.rank
    from public.rooms r, public.leaderboard(d.day, r.id, 'global', 100000, 0) l where l.entry_id = e.id;
    insert into public.notification_outbox (user_id, title, body, data)
    select e.user_id,
           case when e.final_rank = 1 then 'You won today''s arena!' else 'Your photo finished #' || e.final_rank end,
           case when e.room_id is null then 'Out of ' || t.total || ' photos on ' || d.day::text || '. Tap to see the final board.'
                else 'In ' || r.name || ', out of ' || t.total || '. Tap to see the final board.' end,
           jsonb_build_object('day', d.day::text, 'room', e.room_id, 'rank', e.final_rank)
    from public.entries e
    left join public.rooms r on r.id = e.room_id
    join lateral (select count(*) as total from public.entries x where x.day = e.day and x.room_id is not distinct from e.room_id and x.status = 'active') t on true
    where e.day = d.day and e.status = 'active' and e.final_rank is not null
      and exists (select 1 from public.device_tokens dt where dt.user_id = e.user_id);
    update public.days set finalized = true where day = d.day;
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.close_days() from authenticated;
