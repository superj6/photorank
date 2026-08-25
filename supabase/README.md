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
