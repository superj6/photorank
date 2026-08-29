-- GoTrue runs its migrations as supabase_auth_admin and does
-- `create or replace function auth.uid()`; in supabase/postgres images those
-- functions are pre-created by supabase_admin, so hand them over first.
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS f FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'auth' LOOP
    EXECUTE format('ALTER FUNCTION %s OWNER TO supabase_auth_admin', r.f);
  END LOOP;
END $$;
