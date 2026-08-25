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
- **Recaps**: weekly / monthly / yearly ("your year") stories on the same page
  system, surfaced as the first card after a period ends; "Show my year" in
  Settings any time; opt-in weekly/daily reminders.
- **Bracket**: Top 16 single elimination from the Ranking menu, with a
  shareable bracket image. **Share cards**: Top 9 grid and "#1" card.
  **Favourites**: mark Top 10/50 as system favourites or export an album.
- **Widget**: "Today's Duel" on the home screen — tap a side to answer.
- **Progress**: levels, streaks and badges in the hand summary and Settings.
- **Beats** (`lib/core/beats`) keep play fresh: every 20–35 decisions a short
  in-play moment appears — your Top 3, a climber, a head-to-head to settle, a
  deep cut, a themed 10-card deck — plus majors on milestones, a new #1, the
  Top 10 settling, and mode unlocks (new installs start with Duel + Vibe check
  and unlock Rate/Burst/Sort/Challenger/Re-rank at 30/60/100/150/300
  decisions). Every beat is kept under Ranking → Moments and the big ones are
  shareable. Debug builds have "fire a beat" chips in Settings.

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
lib/core/beats     beat.dart (pages/JSON), beat_scheduler.dart, beat_engine.dart, unlocks.dart, late_game.dart
lib/data/db        Drift schema (+ generated database.g.dart)
lib/data/repo      PhotoRepo, RankingRepo (applyCard / undoCard)
lib/data/media     LibraryScanner (photo_manager), ThumbCache
lib/core/bracket   single-elimination bracket model
lib/core/stats     levels and badges
lib/features       play/, beats/, bracket/, browse/, share/, widget/, ranking/, settings/, onboarding/, shell/
android/app/src/main/kotlin/.../DuelWidgetProvider.kt   home-screen widget
```
