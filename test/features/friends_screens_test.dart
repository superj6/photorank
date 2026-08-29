import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/app/providers.dart';
import 'package:photorank/app/theme.dart';
import 'package:photorank/data/arena/arena_api.dart';
import 'package:photorank/data/arena/arena_models.dart';
import 'package:photorank/data/arena/fake_arena_api.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/features/arena/arena_providers.dart';
import 'package:photorank/features/arena/friends_screen.dart';
import 'package:photorank/features/arena/set_boards_screen.dart';
import 'package:photorank/features/arena/set_rank_screen.dart';

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Widget host(AppDatabase db, FakeArenaApi api, Widget child) => ProviderScope(
      overrides: [dbProvider.overrideWithValue(db), arenaApiProvider.overrideWith((_) async => api as ArenaApi?)],
      child: MaterialApp(theme: AppTheme.dark(), home: child),
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('Friends screen lays out with a friend set, people and my set (no layout exceptions)', (tester) async {
    final api = FakeArenaApi();
    await api.signIn();
    await api.claimUsername('me_me', recoveryPhrase: 'apple-bee-cat-dog-egg');
    await api.publishSet(title: 'Mine', items: [for (var i = 0; i < 4; i++) const SetUploadItem(bytes: [1])]);
    await tester.pumpWidget(host(db, api, const FriendsScreen()));
    await settle(tester, frames: 20);
    expect(tester.takeException(), isNull);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.textContaining('@player2'), findsWidgets);
    expect(find.text('Rank it'), findsOneWidget);
    expect(find.text('Boards'), findsWidgets);
    expect(find.text('Follow back'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Set boards and set ranking screens render', (tester) async {
    final api = FakeArenaApi();
    await api.signIn();
    final set = (await api.visibleSets()).firstWhere((s) => !s.mine);
    await tester.pumpWidget(host(db, api, SetBoardsScreen(set: set)));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Everyone'), findsOneWidget);
    expect(find.textContaining('Owner\'s #'), findsWidgets);

    await tester.pumpWidget(host(db, api, SetRankScreen(setId: set.id)));
    await settle(tester);
    // The controller needs the set list loaded first; the screen shows a
    // spinner until then and must not throw.
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
