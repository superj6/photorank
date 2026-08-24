import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/app/providers.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/main.dart';

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
