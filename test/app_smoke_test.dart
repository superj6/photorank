import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/app/providers.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/main.dart';
import 'package:photorank/core/beats/beat.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/repo/beat_repo.dart';
import 'package:photorank/features/play/play_screen.dart';
import 'package:photorank/features/play/session_controller.dart';

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Unmount the app and drain Drift/animation timers so the framework's
/// "no pending timers" invariant holds at teardown.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

Widget app(AppDatabase db, {String at = '/play'}) => ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: PhotoRankApp(initialLocation: at),
    );

void main() {
  beatTests();
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('empty library shows the empty state on Play', (tester) async {
    await tester.pumpWidget(app(db));
    await settle(tester);
    expect(find.text('Nothing to rank yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('onboarding renders its first page', (tester) async {
    await tester.pumpWidget(app(db, at: '/onboarding'));
    await settle(tester);
    expect(find.text('PhotoRank'), findsOneWidget);
    expect(find.text('Let\'s go'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a full hand can be played through to the summary', (tester) async {
    final now = DateTime(2026, 8, 24, 12);
    await PhotoRepo(db).upsertAssets([
      for (var i = 0; i < 40; i++)
        ScannedAsset(mediaId: 'm$i', takenAt: now.subtract(Duration(hours: i)), width: 10, height: 10),
    ], now: now);
    await tester.pumpWidget(app(db));
    await settle(tester);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);

    for (var i = 0; i < 20; i++) {
      await tester.tap(find.text('Pass'));
      await settle(tester, frames: 4);
    }
    await settle(tester);
    expect(find.text('Nice hand.'), findsOneWidget);
    expect(find.text('Deal another hand'), findsOneWidget);

    // Ranking tab renders.
    await tester.tap(find.text('Ranking'));
    await settle(tester);
    expect(find.text('Your ranking'), findsOneWidget);
    await unmount(tester);
  });
}

// ---------------------------------------------------------------------------
// Beats: drive real decisions through the controller.

Future<void> answerCurrent(SessionController ctl, SessionState s) async {
  final c = s.current!;
  switch (c.mode) {
    case GameMode.duel:
    case GameMode.challenger:
      await ctl.answerDuel(c.photoIds.first);
    case GameMode.vibeCheck:
      await ctl.answerVibe(true);
    case GameMode.rate:
      await ctl.answerRate(4);
    case GameMode.bestOfBurst:
      await ctl.answerBurst(c.photoIds.first);
    case GameMode.sort3:
    case GameMode.rerankTop:
      await ctl.answerSort(c.photoIds);
    case GameMode.browseHeart:
      break;
  }
}

void beatTests() {
  testWidgets('beats: first Top 3 at decision 12, Rate unlocks at 30, nothing locked is dealt before', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 8, 24, 12);
    await PhotoRepo(db).upsertAssets([
      for (var i = 0; i < 60; i++)
        ScannedAsset(mediaId: 'm$i', takenAt: now.subtract(Duration(hours: i * 7)), width: 10, height: 10),
    ], now: now);
    await tester.pumpWidget(app(db));
    await settle(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(PlayScreen)));
    final ctl = container.read(sessionProvider.notifier);
    SessionState s() => container.read(sessionProvider);
    expect(s().status, SessionStatus.playing);
    expect(s().hand.every((c) => c.mode == GameMode.duel || c.mode == GameMode.vibeCheck), isTrue,
        reason: 'new installs start with Duel + Vibe check only');

    var sawStandings = false;
    var sawUnlock = false;
    for (var guard = 0; guard < 80 && s().decisions < 31; guard++) {
      if (s().beat != null) {
        await settle(tester, frames: 3);
        final beat = s().beat!;
        if (beat.kind == BeatKind.standings) {
          sawStandings = true;
          expect(s().decisions, 12);
          expect(find.text('Your Top 3'), findsOneWidget);
        }
        if (beat.kind == BeatKind.modeUnlocked) {
          sawUnlock = true;
          expect(s().decisions, 30);
          expect(find.text('Rate'), findsWidgets);
        }
        await ctl.dismissBeat();
        await settle(tester, frames: 2);
        continue;
      }
      if (s().status == SessionStatus.finished) {
        await ctl.start();
        await settle(tester, frames: 4);
        continue;
      }
      await answerCurrent(ctl, s());
      await settle(tester, frames: 2);
    }
    expect(sawStandings, isTrue);
    expect(sawUnlock, isTrue);
    expect(await BeatRepo(db).listBeats().then((b) => b.length), greaterThanOrEqualTo(2));
    await unmount(tester);
  });
}
