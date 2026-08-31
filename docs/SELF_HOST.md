# Running the PhotoRank backend on your own server

The backend is a Supabase stack: Postgres (all game rules are SQL functions in
`supabase/migrations/`), GoTrue auth (anonymous sign-ins), Storage (bucket
`entries`), and one edge function (`send-push`, optional). Supabase publishes
a Docker Compose bundle for self-hosting; PhotoRank needs nothing beyond it.

Requirements: a Linux box with Docker + Compose, a DNS name (e.g.
`api.example.com`), and ports 80/443 reachable.

> **Small server?** The stock bundle below runs ~12 services and wants 2 GB+.
> `supabase/selfhost/` is a trimmed compose file with only the four services
> the app uses (Postgres, GoTrue, PostgREST, Storage) behind your own nginx —
> ~300 MB idle, fine on a 1 GB box with swap. Its README has the short
> procedure; the sections on migrations, cron and the app build below apply
> unchanged. Two gotchas met on a real deploy: the Postgres image's
> `auth.uid()`/`auth.role()` are owned by `supabase_admin`, so GoTrue's
> migrations fail until `ALTER FUNCTION … OWNER TO supabase_auth_admin` (the
> compose's init script handles it), and `docker compose up` may time out on
> the first DB init — run it again.

## 1. Get the Supabase compose bundle

```sh
git clone --depth 1 https://github.com/supabase/supabase
mkdir -p ~/photorank-backend && cp -r supabase/docker/* ~/photorank-backend/
cd ~/photorank-backend && cp .env.example .env
```

## 2. Set the secrets in `.env`

Generate fresh values (never keep the example ones):

```sh
openssl rand -hex 32            # POSTGRES_PASSWORD
openssl rand -hex 32            # JWT_SECRET (>= 32 chars)
openssl rand -hex 16            # DASHBOARD_PASSWORD
```

`ANON_KEY` and `SERVICE_ROLE_KEY` are JWTs signed with your `JWT_SECRET`.
Make them with the generator in Supabase's docs
(<https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys>) or:

```sh
python3 tool/selfhost_keys.py "$JWT_SECRET"     # prints ANON_KEY and SERVICE_ROLE_KEY
```

Then edit `.env`:

| key | value |
|---|---|
| `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `DASHBOARD_USERNAME/PASSWORD` | the values above |
| `SITE_URL`, `API_EXTERNAL_URL`, `SUPABASE_PUBLIC_URL` | `https://api.example.com` |
| `ENABLE_ANONYMOUS_USERS` | `true` — the app signs in anonymously |
| `DISABLE_SIGNUP` | `false` |
| `ENABLE_EMAIL_SIGNUP`, `ENABLE_EMAIL_AUTOCONFIRM` | `false` / `false` (no email flows yet) |
| `STUDIO_DEFAULT_PROJECT` | `PhotoRank` |

(If your bundle's `.env.example` names the anonymous flag differently, set
`GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=true` on the `auth` service in
`docker-compose.yml`.)

## 3. Start it

```sh
docker compose pull && docker compose up -d
docker compose ps        # everything "healthy"; Kong listens on :8000
```

## 4. Apply PhotoRank's migrations

From this repo, with the Supabase CLI (or plain psql):

```sh
export DB="postgres://postgres.your-tenant:$POSTGRES_PASSWORD@api.example.com:5432/postgres"
# CLI (recommended; tracks which migrations ran):
supabase db push --db-url "$DB"
# or psql, in order:
for f in supabase/migrations/*.sql; do psql "$DB" -v ON_ERROR_STOP=1 -f "$f"; done
```

`0001_arena.sql` creates the `entries` storage bucket and its policies, so no
manual Storage setup is needed. Verify:

```sh
psql "$DB" -v ON_ERROR_STOP=1 -f supabase/tests/arena_scenario.sql   # NOTICE: ok: ... x18
psql "$DB" -v ON_ERROR_STOP=1 -f supabase/tests/sets_scenario.sql    # NOTICE: ok: ... x13
```

(The scenarios create fake users; run them on a fresh database, or skip.)

## 5. Close days on a schedule

Days finalise at 00:00 UTC via `close_days()`. Schedule it with pg_cron (in
the self-hosted image):

```sql
create extension if not exists pg_cron;
select cron.schedule('close-days', '5 * * * *', $$select public.close_days()$$);
```

## 6. TLS in front of Kong

Put Caddy (simplest) on the host:

```
api.example.com {
    reverse_proxy localhost:8000
}
```

`caddy run` obtains the certificate automatically. Studio is at
`https://api.example.com/` behind the dashboard password.

## 7. Point the app at it

```sh
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://api.example.com \
  --dart-define=SUPABASE_ANON_KEY="$ANON_KEY"
```

Same two defines for `flutter build linux` / Windows, or add them as
`SUPABASE_URL` / `SUPABASE_ANON_KEY` repository secrets so the release
workflow (`.github/workflows/release.yml`) bakes them into the published
binaries. The anon key is safe to ship; the service-role key never leaves the
server.

## Optional: result push notifications

`supabase/functions/send-push` needs a Firebase service account. On a
self-hosted stack, functions run in the `functions` container: copy
`supabase/functions/send-push` into `volumes/functions/` of the bundle, add
`FCM_SERVICE_ACCOUNT` to `.env`, and schedule the delivery job from
`supabase/README.md` with pg_cron + pg_net.

## Operations

- **Backups**: `docker compose exec db pg_dump -U postgres postgres | gzip > backup.sql.gz`
  plus the `volumes/storage` directory (uploaded photos).
- **Upgrades**: `docker compose pull && docker compose up -d`; run new
  migrations with `supabase db push`.
- **Moderation**: reports land in `public.reports`; hide/ban from Studio's
  table editor (`entries.status`, `profiles.banned`).
- **Alternative**: the same migrations work on a Supabase cloud project
  (`supabase link` + `supabase db push`; enable *Anonymous sign-ins* in Auth
  settings) — no server to run, free tier to start.
