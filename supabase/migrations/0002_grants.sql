-- Table/function grants for the API roles. RLS (0001) still limits rows.
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to authenticated;
grant insert, delete on public.follows, public.blocks to authenticated;
grant insert on public.reports to authenticated;
grant update (username, display_name) on public.profiles to authenticated;
grant execute on all functions in schema public to authenticated;
revoke execute on function public.close_days() from authenticated;
alter default privileges in schema public grant select on tables to authenticated;
alter default privileges in schema public grant execute on functions to authenticated;
