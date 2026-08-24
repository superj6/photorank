#!/usr/bin/env bash
# PhotoRank dev helper: Android emulator lifecycle + fake camera roll.
#   tool/emulator.sh create            # one-time: make the "photorank" AVD (API 35, Pixel 7)
#   tool/emulator.sh start             # boot it (window) and wait until ready
#   tool/emulator.sh seed <dir>        # push JPEGs from <dir> to DCIM/Camera and rescan media
#   tool/emulator.sh run               # flutter run on the emulator
set -euo pipefail
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
AVD=photorank
IMAGE="system-images;android-35;google_apis;x86_64"

case "${1:-}" in
  create)
    echo no | avdmanager create avd -n "$AVD" -k "$IMAGE" -d pixel_7 --force
    cfg="$HOME/.android/avd/$AVD.avd/config.ini"
    sed -i 's/^hw.keyboard=.*/hw.keyboard=yes/' "$cfg" || true
    grep -q '^hw.keyboard' "$cfg" || echo 'hw.keyboard=yes' >> "$cfg"
    grep -q '^disk.dataPartition.size' "$cfg" || echo 'disk.dataPartition.size=4G' >> "$cfg"
    echo "AVD '$AVD' created"
    ;;
  start)
    if adb devices | grep -q emulator-; then echo "emulator already running"; exit 0; fi
    nohup emulator -avd "$AVD" -gpu auto -no-snapshot-load -no-boot-anim \
      >"${EMU_LOG:-/tmp/photorank-emulator.log}" 2>&1 &
    adb wait-for-device
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
    echo "emulator booted"
    ;;
  seed)
    dir="${2:?usage: emulator.sh seed <dir-with-jpgs>}"
    adb shell mkdir -p /sdcard/DCIM/Camera
    adb push "$dir"/. /sdcard/DCIM/Camera/ >/dev/null
    # Ask MediaProvider to rescan the primary volume (Android 10+).
    adb shell content call --uri content://media/none/ --method scan_volume --arg external_primary >/dev/null 2>&1 || \
      adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///sdcard >/dev/null
    sleep 3
    echo "media rows: $(adb shell content query --uri content://media/external/images/media --projection _id 2>/dev/null | grep -c _id)"
    ;;
  run)
    cd "$(dirname "$0")/.."
    flutter run -d "$(adb devices | grep -o 'emulator-[0-9]*' | head -1)" "${@:2}"
    ;;
  *)
    sed -n 2,7p "$0"; exit 1 ;;
esac
