#!/usr/bin/env bash
# A second Arena player driven over the local stack's REST API — for testing
# friends / sets against one real device. State lives in .arena_bot/ (git-ignored).
#   tool/arena_bot.sh new <username>        # create an anonymous user and claim a username
#   tool/arena_bot.sh rpc <fn> ['<json>']   # call a SQL function as the bot
#   tool/arena_bot.sh follow <username>     # follow a player (they must follow back to be friends)
#   tool/arena_bot.sh publish <dir> [n] [visibility]   # upload n JPEGs from <dir> and publish a set
#   tool/arena_bot.sh rank <username>       # rank that owner's set (a full pass, random picks)
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "$0")/.."
URL=http://127.0.0.1:54321
D=.arena_bot; mkdir -p $D
env_of() { sg docker -c "supabase status -o env" 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
KEY=$(env_of ANON_KEY || true); [ -n "$KEY" ] || KEY=$(env_of PUBLISHABLE_KEY)
[ -n "$KEY" ] || { echo "Local stack not running (supabase start)"; exit 1; }
# Tokens are minted from the local JWT secret so they never expire mid-test.
token() {
  python3 - "$(env_of JWT_SECRET)" "$(cat $D/uid)" <<'PY'
import sys, json, hmac, hashlib, base64, time
def b64(b): return base64.urlsafe_b64encode(b).rstrip(b'=').decode()
secret, sub = sys.argv[1], sys.argv[2]
h = b64(json.dumps({"alg":"HS256","typ":"JWT"}).encode())
p = b64(json.dumps({"sub":sub,"role":"authenticated","aud":"authenticated","is_anonymous":True,"iat":int(time.time()),"exp":int(time.time())+3600}).encode())
print(f"{h}.{p}." + b64(hmac.new(secret.encode(), f"{h}.{p}".encode(), hashlib.sha256).digest()))
PY
}
rpc() { curl -s -X POST "$URL/rest/v1/rpc/$1" -H "apikey: $KEY" -H "Authorization: Bearer $(token)" -H "Content-Type: application/json" -d "${2:-{\}}"; echo; }
jq_() { python3 -c "import sys,json; j=json.load(sys.stdin); $1"; }
case "${1:-}" in
  new)
    curl -s -X POST "$URL/auth/v1/signup" -H "apikey: $KEY" -H "Content-Type: application/json" -d '{"data":{}}' | jq_ 'print(j["user"]["id"])' > $D/uid
    rpc claim_username "{\"p_username\":\"$2\"}"; echo "bot user $(cat $D/uid) is @$2" ;;
  rpc) rpc "$2" "${3:-}" ;;
  follow)
    id=$(rpc find_profile "{\"p_username\":\"$2\"}" | jq_ 'print(j[0]["id"] if j else "")'); [ -n "$id" ] || { echo "no such user"; exit 1; }
    curl -s -o /dev/null -w "%{http_code}\n" -X POST "$URL/rest/v1/follows" -H "apikey: $KEY" -H "Authorization: Bearer $(token)" -H "Content-Type: application/json" -H "Prefer: return=minimal,resolution=ignore-duplicates" -d "{\"follower_id\":\"$(cat $D/uid)\",\"followee_id\":\"$id\"}" ;;
  publish)
    uid=$(cat $D/uid); n=${3:-6}; items="["; i=0
    for f in $(ls "$2"/*.jpg | head -"$n"); do
      i=$((i+1)); path="$uid/set/$(date +%s)-$i.jpg"
      curl -s -o /dev/null -X POST "$URL/storage/v1/object/entries/$path" -H "apikey: $KEY" -H "Authorization: Bearer $(token)" -H "Content-Type: image/jpeg" --data-binary @"$f"
      [ $i -gt 1 ] && items+=","; items+="{\"storage_path\":\"$path\",\"taken_at\":\"2026-08-0${i}T10:00:00Z\"}"
    done
    rpc publish_set "{\"p_title\":\"Bot's set\",\"p_items\":$items],\"p_visibility\":\"${4:-friends}\"}" ;;
  rank)
    sid=$(rpc visible_sets | jq_ "print([s['set_id'] for s in j if s['owner_username']=='$2'][0])")
    for i in $(seq 1 60); do
      pair=$(rpc set_next_pairs "{\"p_set\":\"$sid\",\"p_n\":1}"); a=$(echo "$pair" | jq_ 'print(j[0]["a_id"] if j else "")'); [ -n "$a" ] || break
      b=$(echo "$pair" | jq_ 'print(j[0]["b_id"] if j else "")'); w=$([ $((RANDOM % 2)) = 0 ] && echo $a || echo $b)
      rpc set_record_duel "{\"p_set\":\"$sid\",\"p_a\":\"$a\",\"p_b\":\"$b\",\"p_winner\":\"$w\"}" | grep -q "already ranked" && break || true
    done
    rpc visible_sets | jq_ "[print(s['title'], 'done' if s['my_done'] else 'in progress', s['my_duels'], 'duels') for s in j if s['owner_username']=='$2']" ;;
  *) sed -n 2,8p "$0"; exit 1 ;;
esac
