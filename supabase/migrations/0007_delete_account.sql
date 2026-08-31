-- Play policy: users must be able to delete their account in-app.
-- Everything hangs off auth.users / profiles with ON DELETE CASCADE, so one
-- delete removes the profile, entries, duels, sets, ratings, follows, tokens.
-- Storage files are removed by the client first (see my_storage_paths).

create or replace function public.my_storage_paths() returns setof text
language sql security definer set search_path = public stable as $$
  select storage_path from public.entries where user_id = auth.uid()
  union all
  select i.storage_path from public.set_items i join public.sets s on s.id = i.set_id where s.owner_id = auth.uid()
$$;

create or replace function public.delete_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  delete from auth.users where id = auth.uid();
end $$;

grant execute on function public.my_storage_paths(), public.delete_account() to authenticated;
