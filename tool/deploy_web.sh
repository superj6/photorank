#!/usr/bin/env bash
# Build the PWA against a backend and upload it to the server that serves it.
#   SUPABASE_URL=https://photorank.jgon.net SUPABASE_ANON_KEY=... tool/deploy_web.sh root@jgon.net:/var/www/photorank
set -euo pipefail
export PATH="$HOME/development/flutter/bin:$PATH"
cd "$(dirname "$0")/.."
dest="${1:?usage: deploy_web.sh user@host:/path}"
: "${SUPABASE_URL:?set SUPABASE_URL}" "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY}"
flutter build web --release --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
rsync -az --delete build/web/ "$dest/"
echo "deployed to $dest"
