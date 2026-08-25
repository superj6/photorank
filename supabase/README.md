# Arena backend (Supabase)

1. Create a project at https://supabase.com (free tier). In **Authentication →
   Providers** enable *Anonymous sign-ins*.
2. Apply the schema: `supabase link --project-ref <ref>` then `supabase db push`,
   or run `migrations/0001_arena.sql` in the SQL editor.
3. Schedule day closing (SQL editor):
   `select cron.schedule('close-days', '17 * * * *', $$select public.close_days()$$);`
   (enable the `pg_cron` extension first under Database → Extensions).
4. Put the project URL and anon key in the app (see `lib/config/`).

The service-role key is never used by the app.

## Testing the SQL locally
`supabase start` (Docker) applies the migrations. Then run the end-to-end
scenario (simulated users: submit, pair, duel, rooms, reports, day close):

    docker exec -i supabase_db_photorank psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/tests/arena_scenario.sql

Every check prints `NOTICE: ok: …`; any `FAIL` or `ERROR` is a regression.
Run `supabase db reset` before re-running (the scenario is not idempotent).

Point the app at the local stack with `tool/arena_local.sh run emulator|phone`.
