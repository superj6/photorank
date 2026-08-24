# PhotoRank

A tiny game that sorts your camera roll. Every swipe makes your favourites
clearer. Nothing is ever deleted, hidden, or uploaded — photos never leave the
phone; only ratings are stored.

## How it works

- **Play** deals a hand of ~20 cards: Duel, Vibe check (feeling it / not
  feeling it), Rate (1–5★), Best of burst, Sort three, Challenger. Every answer
  becomes pairwise evidence for a Glicko-style rating (`lib/core/rating`).
- **The Dealer** (`lib/core/dealer`) picks photos by uncertainty, recency and
  neglect, pairs duels for maximum information, and always slips one top-tier
  photo into each hand.
- **Browse** is a vertical Flow through your ranking (Top Shelf, Wildcard,
  Time Machine, Deep Cuts) plus "Deal me 9". Double-tap ♥ is a light signal.
- **Ranking** is the grid output; **Settings** controls the game mix, hand
  size and library scope.

Design doc / roadmap: `~/.claude/plans/i-want-to-make-mossy-willow.md`.

## Dev setup (Linux)

Flutter SDK lives in `~/development/flutter`, Android SDK in `~/Android/Sdk`
(both added to `~/.bashrc`). Open a new shell or:

```sh
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
```

```sh
flutter doctor                 # Android toolchain should be ✓
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing lib/data/db/database.dart
flutter test                   # rating engine, dealer, sampler, repo tests
flutter analyze
```

## Run in the Android emulator

An AVD (`photorank`, API 35, Pixel 7) and a fake camera roll are one command
each — `tool/emulator.sh` wraps the details:

```sh
tool/emulator.sh create                       # once
tool/emulator.sh start                        # boots and waits for the device
python3 tool/make_seed_photos.py /tmp/seed    # 85 JPEGs with EXIF dates, bursts, trip days
tool/emulator.sh seed /tmp/seed               # push to DCIM/Camera + media rescan
tool/emulator.sh run                          # flutter run on the emulator
```

Note: Android's MediaProvider ignores EXIF `DateTimeOriginal` unless
`OffsetTimeOriginal` is also present (or the date is within a day of the file
mtime). The seed generator writes both; real camera JPEGs already do.

## Run on an Android phone

1. Enable Developer options → USB debugging on the phone, plug it in, accept
   the RSA prompt.
2. `adb devices` should list it; then:

```sh
flutter run            # debug, hot reload
flutter run --release  # smooth animations, real performance
```

Or install the prebuilt debug APK: `flutter build apk --debug` →
`build/app/outputs/flutter-apk/app-debug.apk` (`adb install -r <apk>`).

## Layout

```
lib/core/rating    glicko.dart, anchors.dart, observation.dart, engine.dart
lib/core/dealer    dealer.dart, priority.dart, burst_cluster.dart, photo_state.dart
lib/core/sampler   rank_sampler.dart (Browse channels)
lib/data/db        Drift schema (+ generated database.g.dart)
lib/data/repo      PhotoRepo, RankingRepo (applyCard / undoCard)
lib/data/media     LibraryScanner (photo_manager), ThumbCache
lib/features       play/, browse/, ranking/, settings/, onboarding/, shell/
```
