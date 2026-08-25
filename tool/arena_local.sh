#!/usr/bin/env bash
# Run / build PhotoRank against the LOCAL Supabase stack (supabase start).
#   tool/arena_local.sh run emulator      # flutter run on the emulator (host = 10.0.2.2)
#   tool/arena_local.sh run phone         # flutter run on the USB phone (host = this PC's LAN IP)
#   tool/arena_local.sh apk emulator|phone  # build a debug APK and install it
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/development/flutter/bin:$HOME/Android/Sdk/platform-tools:$PATH"
cd "$(dirname "$0")/.."
target="${2:-emulator}"
if [ "$target" = "emulator" ]; then host=10.0.2.2; serial=$(adb devices | grep -o 'emulator-[0-9]*' | head -1)
else host=$(hostname -I | awk '{print $1}'); serial=$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator/ {print $1; exit}'); fi
key=$(sg docker -c "supabase status -o env" 2>/dev/null | grep -E '^(ANON_KEY|PUBLISHABLE_KEY)=' | head -1 | cut -d= -f2- | tr -d '"')
[ -n "$key" ] || { echo "Local stack not running (supabase start)"; exit 1; }
defines=(--dart-define=SUPABASE_URL="http://$host:54321" --dart-define=SUPABASE_ANON_KEY="$key")
case "${1:-run}" in
  run) flutter run -d "$serial" "${defines[@]}" ;;
  apk) flutter build apk --debug "${defines[@]}" && adb -s "$serial" install -r build/app/outputs/flutter-apk/app-debug.apk ;;
  *) sed -n 2,5p "$0"; exit 1 ;;
esac
