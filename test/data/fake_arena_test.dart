import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/fake_arena_api.dart';

void main() {
  test('arena rules: one entry, own photo never paired, ratings move, board ranks', () async {
    final api = FakeArenaApi();
    await api.signIn();
    final mine = await api.submit(Uint8List(0));
    expect(mine, isNotNull);
    expect(() => api.submit(Uint8List(0)), throwsStateError);
    final pairs = await api.nextPairs(n: 10);
    expect(pairs, isNotEmpty);
    expect(pairs.every((p) => p.aId != mine!.entryId && p.bId != mine.entryId), isTrue);
    final before = await api.leaderboard();
    final a = pairs.first;
    await api.recordDuel(aId: a.aId, bId: a.bId, winnerId: a.aId);
    expect(() => api.recordDuel(aId: a.aId, bId: a.bId, winnerId: a.aId), throwsStateError);
    final after = await api.leaderboard();
    final muBefore = before.firstWhere((r) => r.entryId == a.aId).mu;
    final muAfter = after.firstWhere((r) => r.entryId == a.aId).mu;
    expect(muAfter, greaterThan(muBefore));
    expect(after.first.rank, 1);
    expect(after.where((r) => r.settled).length, greaterThan(0));
    expect((await api.myEntry())!.settled, isFalse, reason: 'new entry has no duels yet');
    expect((await api.myHistory()).length, greaterThanOrEqualTo(6));
    final room = await api.createRoom('Family');
    expect((await api.leaderboard(roomId: room.id)).length, 4);
  });
}
