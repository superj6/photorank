# Trimmed self-hosted backend (~300 MB)

Four containers — Postgres, GoTrue, PostgREST, Storage — behind your own
nginx. See `docs/SELF_HOST.md` for the full walkthrough; the short form:

```sh
scp -r supabase/selfhost root@host:/opt/photorank && ssh root@host
cd /opt/photorank && cp .env.example .env && $EDITOR .env      # secrets + API_EXTERNAL_URL
docker compose up -d && docker compose ps                     # all healthy
# nginx: copy nginx-api.conf to sites-available, set server_name, enable, certbot --nginx -d api.host
```

Then from the repo (replace the password):

```sh
DB="postgres://postgres:PASSWORD@127.0.0.1:5432/postgres"   # over `ssh -L 5432:127.0.0.1:5432 root@host`
for f in supabase/migrations/*.sql; do psql "$DB" -v ON_ERROR_STOP=1 -f "$f"; done
psql "$DB" -c "select cron.schedule('close-days','5 * * * *', \$\$select public.close_days()\$\$)"
```

Data lives in `data/db` and `data/storage` — back those two directories up.
